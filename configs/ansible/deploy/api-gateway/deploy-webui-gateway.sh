#!/bin/bash
# Deploy WebUI Gateway Server
# Script: /opt/CX-Dev-Test-Infrastructure/configs/ansible/deploy/api-gateway/deploy-webui-gateway.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="/opt/CX-Dev-Test-Infrastructure/configs/ansible"
PLAYBOOK_PATH="${SCRIPT_DIR}/deploy-webui-gateway.yml"
INVENTORY_PATH="${ANSIBLE_DIR}/inventory/main.yaml"
LOG_DIR="/opt/CX-Dev-Test-Infrastructure/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/webui-gateway-deployment_${TIMESTAMP}.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "🚀 WebUI Gateway Deployment"
echo "=========================================="
echo "Timestamp: $(date)"
echo "Playbook: $PLAYBOOK_PATH"
echo "Inventory: $INVENTORY_PATH"
echo "Log File: $LOG_FILE"
echo "=========================================="

# Change to ansible directory for proper relative paths
cd "$ANSIBLE_DIR"

# Run pre-flight checks
echo "🔍 Running pre-flight checks..."
if ansible-playbook playbooks/preflight-checks.yml -i "$INVENTORY_PATH" --limit api_gateway_servers; then
    echo "✅ Pre-flight checks passed"
else
    echo "❌ Pre-flight checks failed"
    exit 1
fi

# Get API Gateway server IP from inventory
echo "🔍 Extracting API Gateway server IP from inventory..."

# Extract IP using reliable grep/cut method
API_GATEWAY_IP=$(ansible-inventory -i "$INVENTORY_PATH" --host hx-api-gateway-server | grep '"ansible_host"' | cut -d'"' -f4)

if [[ -z "$API_GATEWAY_IP" ]]; then
    echo "❌ Failed to extract API Gateway IP from inventory"
    echo "   Ensure hx-api-gateway-server exists in inventory and has ansible_host defined"
    exit 1
fi

echo "📍 API Gateway server IP: $API_GATEWAY_IP"

# Run the deployment
echo ""
echo "🚀 Starting WebUI Gateway deployment..."
if ansible-playbook "$PLAYBOOK_PATH" -i "$INVENTORY_PATH" --verbose 2>&1 | tee "$LOG_FILE"; then
    echo ""
    echo "✅ WebUI Gateway deployment completed successfully!"
    echo "📊 Check deployment status at: /opt/webui-gateway/deployment_status.txt"
    echo "📋 Service management:"
    echo "   - Status: sudo systemctl status cx-webui-gateway"
    echo "   - Logs:   sudo journalctl -u cx-webui-gateway -f"
    echo "   - Test:   curl http://${API_GATEWAY_IP}:8001/api/tags"
else
    echo ""
    echo "❌ WebUI Gateway deployment failed!"
    echo "📋 Troubleshooting:"
    echo "   - Check logs: $LOG_FILE"
    echo "   - Service status: sudo systemctl status cx-webui-gateway"
    echo "   - Service logs: sudo journalctl -u cx-webui-gateway -n 50"
    exit 1
fi

echo ""
echo "=========================================="
echo "🎉 Deployment Complete!"
echo "=========================================="
