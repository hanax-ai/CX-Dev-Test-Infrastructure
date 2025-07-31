#!/bin/bash

# CX Embedding Models Deployment Script
# Automated deployment using Ansible

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR"
LOGDIR="$ANSIBLE_DIR/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEPLOYMENT_LOG="$LOGDIR/deployment_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create logs directory
mkdir -p "$LOGDIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CX Embedding Models Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Timestamp: $(date)${NC}"
echo -e "${YELLOW}Log file: $DEPLOYMENT_LOG${NC}"
echo ""

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$DEPLOYMENT_LOG"
}

# Function to check prerequisites
check_prerequisites() {
    log_message "Checking prerequisites..."
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}ERROR: Ansible is not installed${NC}"
        echo "Please install Ansible first:"
        echo "  pip install ansible"
        exit 1
    fi
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo -e "${RED}ERROR: SSH private key not found at ~/.ssh/id_rsa${NC}"
        echo "Please ensure SSH key is configured for server access"
        exit 1
    fi
    
    # Test connectivity to orchestration server
    log_message "Testing connectivity to orchestration server..."
    if ! ansible orchestration -m ping -i "$ANSIBLE_DIR/inventory/hosts.yml" &>> "$DEPLOYMENT_LOG"; then
        echo -e "${RED}ERROR: Cannot connect to orchestration server${NC}"
        echo "Please check:"
        echo "  - SSH key is configured"
        echo "  - Server 192.168.10.31 is accessible"
        echo "  - User agent0 has sudo privileges"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Prerequisites check passed${NC}"
}

# Function to run deployment
run_deployment() {
    log_message "Starting embedding models deployment..."
    
    echo -e "${YELLOW}Deploying embedding models to CX Orchestration Server...${NC}"
    
    # Run the ansible playbook
    if ansible-playbook \
        -i "$ANSIBLE_DIR/inventory/hosts.yml" \
        "$ANSIBLE_DIR/playbooks/deploy-embedding-models.yml" \
        --verbose \
        2>&1 | tee -a "$DEPLOYMENT_LOG"; then
        
        echo -e "${GREEN}✓ Deployment completed successfully${NC}"
        log_message "Deployment completed successfully"
        return 0
    else
        echo -e "${RED}✗ Deployment failed${NC}"
        log_message "Deployment failed"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    log_message "Verifying deployment..."
    
    echo -e "${YELLOW}Testing embedding models...${NC}"
    
    # Test each model endpoint
    models=("mxbai-embed-large" "nomic-embed-text" "all-minilm")
    
    for model in "${models[@]}"; do
        echo -n "Testing $model: "
        if curl -s -X POST "http://192.168.10.31:11434/api/embeddings" \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"$model\",\"prompt\":\"test\"}" \
            --max-time 30 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Working${NC}"
            log_message "$model: Working"
        else
            echo -e "${RED}✗ Failed${NC}"
            log_message "$model: Failed"
        fi
    done
}

# Function to display summary
display_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Deployment Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}Server:${NC} hx-orc-server (192.168.10.31)"
    echo -e "${YELLOW}Models Installed:${NC}"
    echo "  - mxbai-embed-large (334M parameters)"
    echo "  - nomic-embed-text (137M parameters)"
    echo "  - all-minilm (23M parameters)"
    echo ""
    echo -e "${YELLOW}API Endpoints:${NC}"
    echo "  - http://192.168.10.31:11434/api/embeddings"
    echo ""
    echo -e "${YELLOW}Usage Example:${NC}"
    echo '  curl -X POST "http://192.168.10.31:11434/api/embeddings" \'
    echo '    -H "Content-Type: application/json" \'
    echo '    -d '"'"'{"model":"mxbai-embed-large","prompt":"Your text here"}'"'"
    echo ""
    echo -e "${YELLOW}Log File:${NC} $DEPLOYMENT_LOG"
    echo -e "${BLUE}========================================${NC}"
}

# Main execution
main() {
    check_prerequisites
    
    if run_deployment; then
        verify_deployment
        display_summary
        echo -e "${GREEN}🎉 Embedding models deployment completed successfully!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Deployment failed. Check logs: $DEPLOYMENT_LOG${NC}"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --dry-run)
        echo -e "${YELLOW}Running dry-run...${NC}"
        ansible-playbook \
            -i "$ANSIBLE_DIR/inventory/hosts.yml" \
            "$ANSIBLE_DIR/playbooks/deploy-embedding-models.yml" \
            --check \
            --diff
        ;;
    --verify-only)
        echo -e "${YELLOW}Running verification only...${NC}"
        verify_deployment
        ;;
    --help)
        echo "CX Embedding Models Deployment Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --dry-run      Run in dry-run mode (no changes made)"
        echo "  --verify-only  Only verify existing deployment"
        echo "  --help         Show this help message"
        echo ""
        echo "Default: Run full deployment"
        ;;
    *)
        main
        ;;
esac
