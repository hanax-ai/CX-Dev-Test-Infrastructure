#!/bin/bash
# Phase 3 Deployment Script for CX-Dev and CX-Test Servers
# Citadel Alpha Infrastructure - Development & Testing Environment
# Date: July 31, 2025

set -e

echo "==============================================="
echo "Phase 3: Development & Testing Server Deployment"
echo "Citadel Alpha Infrastructure Project"
echo "==============================================="
echo "Target Servers:"
echo "- CX-Dev Server: 192.168.10.33 (Development)"
echo "- CX-Test Server: 192.168.10.34 (Testing)"
echo "Date: $(date)"
echo ""

# Variables
DEV_SERVER="192.168.10.33"
TEST_SERVER="192.168.10.34"
SSH_USER="agent0"
DEPLOYMENT_LOG="/opt/CX-Dev-Test-Infrastructure/logs/phase3-deployment.log"

# Create logs directory
mkdir -p /opt/CX-Dev-Test-Infrastructure/logs

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$DEPLOYMENT_LOG"
}

log_message "=== Phase 3 Deployment Started ==="

# Step 1: Verify DevOps server prerequisites
echo "Step 1: Verifying DevOps server prerequisites..."
log_message "Verifying prerequisites on DevOps server"

# Check if we're in the correct directory
if [ ! -f "configs/ansible/inventory.yml" ]; then
    echo "ERROR: Must run from /opt/CX-Dev-Test-Infrastructure directory"
    exit 1
fi

# Check Ansible installation
if ! command -v ansible &> /dev/null; then
    echo "ERROR: Ansible not found. Please install Ansible first."
    exit 1
fi

# Check if SSH key exists
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "SSH key not found. Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "agent0@cx-devops-server"
    log_message "Generated SSH key for agent0"
fi

echo "✅ Prerequisites verified"
log_message "Prerequisites check completed"

# Step 2: SSH Key Setup Instructions
echo ""
echo "Step 2: SSH Access Setup Required"
echo "================================="
echo "Before proceeding with automated deployment, you need to set up SSH access"
echo "to the target servers. Please perform the following manual steps:"
echo ""
echo "For CX-Dev Server (192.168.10.33):"
echo "1. ssh-copy-id agent0@192.168.10.33"
echo "   OR"
echo "2. Manually copy the public key:"
echo "   cat ~/.ssh/id_rsa.pub"
echo "   Then add this key to /home/agent0/.ssh/authorized_keys on 192.168.10.33"
echo ""
echo "For CX-Test Server (192.168.10.34):"
echo "1. ssh-copy-id agent0@192.168.10.34"
echo "   OR"
echo "2. Manually copy the public key:"
echo "   cat ~/.ssh/id_rsa.pub"
echo "   Then add this key to /home/agent0/.ssh/authorized_keys on 192.168.10.34"
echo ""

# Display the public key for easy copying
echo "Your public key (copy this to target servers):"
echo "=============================================="
cat ~/.ssh/id_rsa.pub
echo ""

# Step 3: Connectivity Test
echo "Step 3: Testing connectivity to target servers..."
log_message "Testing connectivity to target servers"

# Test CX-Dev Server
echo "Testing CX-Dev Server (192.168.10.33)..."
if ansible -i configs/ansible/inventory.yml -m ping development > /dev/null 2>&1; then
    echo "✅ CX-Dev Server is reachable"
    DEV_REACHABLE=true
    log_message "CX-Dev Server connectivity: SUCCESS"
else
    echo "❌ CX-Dev Server is not reachable"
    DEV_REACHABLE=false
    log_message "CX-Dev Server connectivity: FAILED"
fi

# Test CX-Test Server
echo "Testing CX-Test Server (192.168.10.34)..."
if ansible -i configs/ansible/inventory.yml -m ping test > /dev/null 2>&1; then
    echo "✅ CX-Test Server is reachable"
    TEST_REACHABLE=true
    log_message "CX-Test Server connectivity: SUCCESS"
else
    echo "❌ CX-Test Server is not reachable"
    TEST_REACHABLE=false
    log_message "CX-Test Server connectivity: FAILED"
fi

# Step 4: Conditional Deployment
if [ "$DEV_REACHABLE" = true ] && [ "$TEST_REACHABLE" = true ]; then
    echo ""
    echo "Step 4: Both servers are reachable. Proceeding with automated deployment..."
    log_message "Starting automated deployment - both servers reachable"
    
    # Run the Phase 3 deployment playbook
    echo "Executing Phase 3 deployment playbook..."
    if ansible-playbook -i configs/ansible/inventory.yml configs/ansible/phase3-deployment.yml -v; then
        echo ""
        echo "🎉 Phase 3 Deployment Completed Successfully!"
        echo "============================================="
        echo "✅ CX-Dev Server deployed at 192.168.10.33"
        echo "   - VS Code Server: http://192.168.10.33:8080"
        echo "   - Password: citadel-dev-2025"
        echo ""
        echo "✅ CX-Test Server deployed at 192.168.10.34"
        echo "   - Automated testing framework ready"
        echo ""
        log_message "Phase 3 deployment completed successfully"
    else
        echo "❌ Deployment failed. Check the logs for details."
        log_message "Phase 3 deployment failed"
        exit 1
    fi
else
    echo ""
    echo "Step 4: Manual SSH setup required before automated deployment"
    echo "==========================================================="
    echo "Please complete the SSH key setup mentioned in Step 2, then run:"
    echo ""
    echo "  # Test connectivity:"
    echo "  ansible -i configs/ansible/inventory.yml -m ping development"
    echo "  ansible -i configs/ansible/inventory.yml -m ping test"
    echo ""
    echo "  # Run deployment:"
    echo "  ansible-playbook -i configs/ansible/inventory.yml configs/ansible/phase3-deployment.yml -v"
    echo ""
    echo "Alternatively, you can re-run this script after setting up SSH access."
    log_message "Manual SSH setup required before proceeding"
fi

# Step 5: Generate deployment documentation
echo ""
echo "Step 5: Generating deployment documentation..."
cat > /opt/CX-Dev-Test-Infrastructure/logs/phase3-status.md << EOF
# Phase 3 Deployment Status Report

**Date:** $(date)  
**Phase:** Development & Testing Infrastructure  
**Servers:** CX-Dev (192.168.10.33) & CX-Test (192.168.10.34)  

## Deployment Summary

- **CX-Dev Server Status:** $([ "$DEV_REACHABLE" = true ] && echo "✅ REACHABLE" || echo "❌ SSH ACCESS REQUIRED")
- **CX-Test Server Status:** $([ "$TEST_REACHABLE" = true ] && echo "✅ REACHABLE" || echo "❌ SSH ACCESS REQUIRED")

## Manual Setup Instructions

If servers are not reachable, complete these steps:

### SSH Key Setup
\`\`\`bash
# Copy SSH key to CX-Dev Server
ssh-copy-id agent0@192.168.10.33

# Copy SSH key to CX-Test Server  
ssh-copy-id agent0@192.168.10.34
\`\`\`

### Automated Deployment
\`\`\`bash
cd /opt/CX-Dev-Test-Infrastructure
ansible-playbook -i configs/ansible/inventory.yml configs/ansible/phase3-deployment.yml -v
\`\`\`

## Expected Results

After successful deployment:

### CX-Dev Server (192.168.10.33)
- Python 3.12.3 virtual environment at /opt/citadel/env
- VS Code Server accessible at http://192.168.10.33:8080
- Development tools: Docker, Node.js, database clients
- Password for VS Code: citadel-dev-2025

### CX-Test Server (192.168.10.34)
- Python 3.12.3 virtual environment at /opt/citadel/env
- Testing frameworks: pytest, selenium, playwright
- Performance testing: locust
- Automated test execution: /opt/citadel/testing/run_tests.sh

## Next Steps

1. Complete Phase 3 deployment
2. Verify both development and testing environments
3. Prepare for Phase 4: AI Processing Tier
4. Target date for Phase 4: August 8-15, 2025
EOF

echo "✅ Phase 3 deployment documentation generated"
echo "📄 Status report: /opt/CX-Dev-Test-Infrastructure/logs/phase3-status.md"
echo "📋 Deployment log: $DEPLOYMENT_LOG"

log_message "=== Phase 3 Deployment Script Completed ==="

echo ""
echo "Phase 3 Deployment Script completed."
echo "Check the status report and logs for next steps."
