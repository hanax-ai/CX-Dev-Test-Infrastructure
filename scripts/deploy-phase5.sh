#!/bin/bash
# Citadel Alpha - Phase 5 Deployment Script
# API Gateway & Web Services Tier Automated Deployment
# Generated: August 2, 2025

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="/opt/CX-Dev-Test-Infrastructure"
ANSIBLE_DIR="${PROJECT_ROOT}/configs/ansible"
INVENTORY_FILE="${ANSIBLE_DIR}/phase5-inventory.yml"
DEPLOYMENT_LOG="/tmp/phase5_deployment_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp}: $message" | tee -a "$DEPLOYMENT_LOG"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp}: $message" | tee -a "$DEPLOYMENT_LOG"
            ;;
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp}: $message" | tee -a "$DEPLOYMENT_LOG"
            ;;
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp}: $message" | tee -a "$DEPLOYMENT_LOG"
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    log INFO "Checking deployment prerequisites..."
    
    # Check if running as root or with sudo
    if [[ $EUID -eq 0 ]]; then
        log ERROR "This script should not be run as root"
        exit 1
    fi
    
    # Check Ansible installation
    if ! command -v ansible-playbook &> /dev/null; then
        log ERROR "Ansible is not installed"
        exit 1
    fi
    
    # Check if inventory file exists
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        log ERROR "Inventory file not found: $INVENTORY_FILE"
        exit 1
    fi
    
    # Check if playbook exists
    if [[ ! -f "${ANSIBLE_DIR}/deploy-phase5.yml" ]]; then
        log ERROR "Phase 5 playbook not found"
        exit 1
    fi
    
    log INFO "Prerequisites check passed"
}

# Function to validate Phase 4 dependencies
validate_phase4_dependencies() {
    log INFO "Validating Phase 4 LLM server dependencies..."
    
    local llm_servers=(
        "192.168.10.29:11434"  # CX-LLM Server 01 (Chat)
        "192.168.10.28:11434"  # CX-LLM Server 02 (Instruct)
        "192.168.10.31:11434"  # CX-Orchestration (Embedding)
    )
    
    local failed_servers=()
    
    for server in "${llm_servers[@]}"; do
        if curl -s --connect-timeout 5 "http://${server}/api/tags" > /dev/null; then
            log INFO "✅ LLM Server ${server} is accessible"
        else
            log WARN "❌ LLM Server ${server} is not accessible"
            failed_servers+=("$server")
        fi
    done
    
    if [[ ${#failed_servers[@]} -gt 0 ]]; then
        log WARN "Some Phase 4 LLM servers are not accessible:"
        for server in "${failed_servers[@]}"; do
            log WARN "  - $server"
        done
        log WARN "Phase 5 deployment will continue, but some features may not work properly"
    else
        log INFO "All Phase 4 dependencies validated successfully"
    fi
}

# Function to deploy Phase 5 servers sequentially
deploy_phase5_sequential() {
    log INFO "Starting Phase 5 sequential deployment..."
    
    # Step 1: Database Server (CX-Database .35)
    log INFO "🗄️  Step 1: Deploying Database Server (PostgreSQL + Redis)"
    if ansible-playbook -i "$INVENTORY_FILE" "${ANSIBLE_DIR}/deploy-phase5-simple.yml" \
        --limit database_servers \
        --verbose >> "$DEPLOYMENT_LOG" 2>&1; then
        log INFO "✅ Database Server deployment completed"
    else
        log ERROR "❌ Database Server deployment failed"
        return 1
    fi
    
    # Step 2: Vector Database Server (CX-Vector Database .30)
    log INFO "🔍 Step 2: Deploying Vector Database Server (Qdrant)"
    if ansible-playbook -i "$INVENTORY_FILE" "${ANSIBLE_DIR}/deploy-phase5-simple.yml" \
        --limit vector_db_servers \
        --verbose >> "$DEPLOYMENT_LOG" 2>&1; then
        log INFO "✅ Vector Database Server deployment completed"
    else
        log ERROR "❌ Vector Database Server deployment failed"
        return 1
    fi
    
    # Step 3: API Gateway Server (CX-API Gateway .39)
    log INFO "🚪 Step 3: Deploying API Gateway Server (FastAPI)"
    if ansible-playbook -i "$INVENTORY_FILE" "${ANSIBLE_DIR}/deploy-phase5-simple.yml" \
        --limit api_gateway_servers \
        --verbose >> "$DEPLOYMENT_LOG" 2>&1; then
        log INFO "✅ API Gateway Server deployment completed"
    else
        log ERROR "❌ API Gateway Server deployment failed"
        return 1
    fi
    
    # Step 4: Web Interface Server (CX-Web .38)
    log INFO "🌐 Step 4: Deploying Web Interface Server (Open WebUI)"
    if ansible-playbook -i "$INVENTORY_FILE" "${ANSIBLE_DIR}/deploy-phase5-simple.yml" \
        --limit web_servers \
        --verbose >> "$DEPLOYMENT_LOG" 2>&1; then
        log INFO "✅ Web Interface Server deployment completed"
    else
        log ERROR "❌ Web Interface Server deployment failed"
        return 1
    fi
    
    log INFO "🎉 Phase 5 sequential deployment completed successfully!"
}

# Function to validate deployment
validate_deployment() {
    log INFO "Validating Phase 5 deployment..."
    
    # Check services
    local services=(
        "Database (PostgreSQL):192.168.10.35:5432"
        "Database (Redis):192.168.10.35:6379"
        "Vector Database (Qdrant):192.168.10.30:6333"
        "API Gateway:192.168.10.39:8000"
        "Web Interface:192.168.10.38:3000"
    )
    
    local failed_services=()
    
    for service in "${services[@]}"; do
        local name="${service%%:*}"
        local endpoint="${service#*:}"
        
        if timeout 10 bash -c "</dev/tcp/${endpoint/:// }" 2>/dev/null; then
            log INFO "✅ $name is accessible"
        else
            log WARN "❌ $name is not accessible at $endpoint"
            failed_services+=("$name")
        fi
    done
    
    # Test API Gateway health
    if curl -s --connect-timeout 10 "http://192.168.10.39:8000/health" > /dev/null; then
        log INFO "✅ API Gateway health check passed"
    else
        log WARN "❌ API Gateway health check failed"
        failed_services+=("API Gateway Health")
    fi
    
    # Test Web Interface
    if curl -s --connect-timeout 10 "http://192.168.10.38:3000" > /dev/null; then
        log INFO "✅ Web Interface accessibility check passed"
    else
        log WARN "❌ Web Interface accessibility check failed"
        failed_services+=("Web Interface")
    fi
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        log INFO "🎉 All Phase 5 services are operational!"
        return 0
    else
        log WARN "Some services failed validation:"
        for service in "${failed_services[@]}"; do
            log WARN "  - $service"
        done
        return 1
    fi
}

# Function to generate deployment report
generate_deployment_report() {
    log INFO "Generating Phase 5 deployment report..."
    
    local report_file="/tmp/phase5_deployment_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Citadel Alpha - Phase 5 Deployment Report

**Deployment Date:** $(date)
**Phase:** 5 - API Gateway & Web Services Tier
**Status:** $1

## Infrastructure Summary

### Servers Deployed
- **CX-Database (192.168.10.35):** PostgreSQL 15 + Redis 7
- **CX-Vector Database (192.168.10.30):** Qdrant 1.8.0
- **CX-API Gateway (192.168.10.39):** FastAPI + Nginx
- **CX-Web (192.168.10.38):** Open WebUI + Node.js 18

### Service Endpoints
- **Web Interface:** http://192.168.10.38:3000
- **API Gateway:** http://192.168.10.39:8000
- **Vector Database:** http://192.168.10.30:6333
- **Database:** PostgreSQL@192.168.10.35:5432

### Phase 4 Dependencies
- **CX-LLM Server 01:** 192.168.10.29:11434 (Chat Models)
- **CX-LLM Server 02:** 192.168.10.28:11434 (Instruct Models) 
- **CX-Orchestration:** 192.168.10.31:11434 (Embedding)

### Technical Stack
- **Databases:** PostgreSQL 15, Redis 7, Qdrant 1.8.0
- **API Framework:** FastAPI with Python 3.12
- **Web Framework:** Open WebUI with Node.js 18
- **Authentication:** Clerk Integration
- **Load Balancing:** Nginx reverse proxy
- **Monitoring:** Health checks + metrics endpoints

## Deployment Log
See: $DEPLOYMENT_LOG

## Next Steps
1. Configure authentication providers
2. Upload initial document corpus
3. Configure user permissions
4. Setup monitoring dashboards
5. Plan production security hardening

---
*Generated by Citadel Alpha Phase 5 Deployment Script*
EOF

    log INFO "Deployment report generated: $report_file"
    echo "Report location: $report_file"
}

# Main execution
main() {
    echo "============================================================="
    echo " CITADEL ALPHA - PHASE 5 DEPLOYMENT"
    echo " API Gateway & Web Services Tier"
    echo " $(date)"
    echo "============================================================="
    
    log INFO "Starting Phase 5 deployment process..."
    
    # Change to project directory
    cd "$PROJECT_ROOT" || {
        log ERROR "Failed to change to project directory: $PROJECT_ROOT"
        exit 1
    }
    
    # Execute deployment steps
    check_prerequisites
    validate_phase4_dependencies
    
    if deploy_phase5_sequential; then
        log INFO "Phase 5 deployment completed successfully"
        
        sleep 30  # Wait for services to fully start
        
        if validate_deployment; then
            log INFO "Phase 5 validation passed"
            generate_deployment_report "SUCCESS"
            
            echo ""
            echo "============================================================="
            echo " PHASE 5 DEPLOYMENT SUCCESSFUL! 🎉"
            echo "============================================================="
            echo " Web Interface: http://192.168.10.38:3000"
            echo " API Gateway:   http://192.168.10.39:8000"
            echo " Vector DB:     http://192.168.10.30:6333"
            echo " Database:      PostgreSQL@192.168.10.35:5432"
            echo "============================================================="
            
            exit 0
        else
            log WARN "Phase 5 deployment completed but validation failed"
            generate_deployment_report "DEPLOYED_WITH_WARNINGS"
            exit 2
        fi
    else
        log ERROR "Phase 5 deployment failed"
        generate_deployment_report "FAILED"
        exit 1
    fi
}

# Execute main function
main "$@"
