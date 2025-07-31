#!/bin/bash
# CX R&D Infrastructure Health Check Script
# Comprehensive health monitoring for all infrastructure servers
# Updated: July 31, 2025

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
LOG_FILE="${PROJECT_ROOT}/logs/health-check-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="${PROJECT_ROOT}/reports/health-report-$(date +%Y%m%d-%H%M%S).json"

# Create directories if they don't exist
mkdir -p "${PROJECT_ROOT}/logs" "${PROJECT_ROOT}/reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Server definitions
declare -A SERVERS=(
    ["cx-web"]="192.168.10.28:80:Web Server"
    ["cx-api-gateway"]="192.168.10.29:8000:API Gateway"
    ["cx-database"]="192.168.10.30:5432:Database Server"
    ["cx-vector-db"]="192.168.10.31:6333:Vector Database"
    ["cx-llm-orchestration"]="192.168.10.32:8080:LLM Orchestration"
    ["cx-test"]="192.168.10.33:3000:Test Server"
    ["cx-metric"]="192.168.10.34:9090:Metrics Server"
    ["cx-dev"]="192.168.10.35:8080:Development Server"
    ["cx-devops"]="192.168.10.36:8080:DevOps Server"
)

# Logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Enhanced health check function
check_server() {
    local name=$1
    local ip=$2
    local port=$3
    local role=$4
    local start_time=$(date +%s.%N)
    
    log "INFO" "Checking $name ($role) at $ip:$port"
    
    # Port connectivity check
    if timeout 5 nc -z "$ip" "$port" >/dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc)
        
        echo -e "${GREEN}✅ $name${NC} ($role) - ${CYAN}ONLINE${NC} (${response_time}s)"
        log "SUCCESS" "$name is online (response time: ${response_time}s)"
        
        # Additional HTTP check if port suggests web service
        if [[ "$port" =~ ^(80|8000|8080|3000|9090)$ ]]; then
            if curl -s -o /dev/null -w "%{http_code}" "http://$ip:$port" --connect-timeout 5 | grep -q "^[23]"; then
                echo -e "  ${BLUE}🌐 HTTP Service${NC} - ${GREEN}Responding${NC}"
                log "INFO" "$name HTTP service is responding"
            else
                echo -e "  ${YELLOW}🌐 HTTP Service${NC} - ${YELLOW}No Response${NC}"
                log "WARN" "$name HTTP service not responding"
            fi
        fi
        
        return 0
    else
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc)
        
        echo -e "${RED}❌ $name${NC} ($role) - ${RED}OFFLINE${NC} (timeout: ${response_time}s)"
        log "ERROR" "$name is offline (timeout: ${response_time}s)"
        return 1
    fi
}

# System health check
check_system_health() {
    echo -e "\n${PURPLE}🔧 System Health Check${NC}"
    echo "=========================="
    
    # Disk usage
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        echo -e "${RED}💾 Disk Usage: ${disk_usage}% - WARNING${NC}"
        log "WARN" "High disk usage: ${disk_usage}%"
    else
        echo -e "${GREEN}💾 Disk Usage: ${disk_usage}% - OK${NC}"
        log "INFO" "Disk usage: ${disk_usage}%"
    fi
    
    # Memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt 80 ]; then
        echo -e "${RED}🧠 Memory Usage: ${mem_usage}% - WARNING${NC}"
        log "WARN" "High memory usage: ${mem_usage}%"
    else
        echo -e "${GREEN}🧠 Memory Usage: ${mem_usage}% - OK${NC}"
        log "INFO" "Memory usage: ${mem_usage}%"
    fi
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo -e "${CYAN}⚡ Load Average: ${load_avg}${NC}"
    log "INFO" "System load average: ${load_avg}"
}

# Generate JSON report
generate_report() {
    local total=$1
    local online=$2
    local offline=$3
    
    cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "infrastructure": "CX R&D Infrastructure",
  "health_check": {
    "total_servers": $total,
    "online_servers": $online,
    "offline_servers": $offline,
    "success_rate": $(echo "scale=2; $online * 100 / $total" | bc)
  },
  "system": {
    "disk_usage_percent": $(df -h / | awk 'NR==2 {print $5}' | sed 's/%//'),
    "memory_usage_percent": $(free | awk 'NR==2{printf "%.0f", $3*100/$2}'),
    "load_average": "$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')"
  }
}
