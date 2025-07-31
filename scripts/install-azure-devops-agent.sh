#!/bin/bash
set -e

echo "==============================================="
echo "Azure DevOps Agent Installation Script"
echo "CX R&D Infrastructure - DevOps Server"
echo "Organization: hana-x"
echo "==============================================="

# Prerequisites: Ensure required packages are installed
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y git curl wget

# Create agent directory
echo "Creating agent directory..."
mkdir -p ~/myagent && cd ~/myagent

# Download Azure DevOps Agent
echo "Downloading Azure DevOps Agent..."
AGENT_VERSION="3.250.1"
DOWNLOAD_URL="https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"

# Try alternative download methods
if ! wget -q --timeout=30 "$DOWNLOAD_URL" 2>/dev/null; then
    echo "Primary download failed, trying alternative method..."
    curl -L -o "vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz" "$DOWNLOAD_URL" || {
        echo "Download failed. Manual download required."
        echo "Please download from: https://github.com/Microsoft/azure-pipelines-agent/releases"
        exit 1
    }
fi

# Extract
echo "Extracting agent package..."
tar zxf vsts-agent-linux-x64-*.tar.gz

# Install dependencies
echo "Installing agent dependencies..."
sudo ./bin/installdependencies.sh

echo "=================================================="
echo "AZURE DEVOPS AGENT READY FOR CONFIGURATION"
echo "=================================================="
echo ""
echo "SECURITY NOTICE:"
echo "Use Personal Access Token (PAT) instead of password for authentication"
echo ""
echo "To create a PAT:"
echo "1. Go to: https://dev.azure.com/hana-x/"
echo "2. Click: User Settings (top right) > Personal Access Tokens"
echo "3. Click: New Token"
echo "4. Set Name: 'CX-DevOps-Agent'"
echo "5. Set Scope: 'Agent Pools (read, manage)'"
echo "6. Copy the generated token"
echo ""
echo "CONFIGURATION STEPS:"
echo "1. Navigate to: cd ~/myagent"
echo "2. Run: ./config.sh"
echo "3. Enter configuration:"
echo "   - Server URL: https://dev.azure.com/hana-x"
echo "   - Authentication type: PAT"
echo "   - Personal Access Token: [paste your PAT here]"
echo "   - Agent pool: Default"
echo "   - Agent name: hx-dev-ops-agent-01"
echo "   - Work folder: _work"
echo ""
echo "4. Install as service:"
echo "   sudo ./svc.sh install agent0"
echo "   sudo ./svc.sh start"
echo "   sudo ./svc.sh status"
echo ""
echo "5. Verify in: https://dev.azure.com/hana-x/_settings/agentpools"
echo "=================================================="
