# Azure DevOps Agent Manual Setup Guide
## CX R&D Infrastructure - DevOps Server Integration with Hana-X

### Prerequisites Complete ✅
- Git: Installed
- User: agent0 configured
- Server: hx-dev-ops-server (192.168.10.36)

### Manual Setup Steps:

#### Step 1: Download Agent
1. Go to: https://dev.azure.com/hana-x/
2. Navigate: Organization Settings > Agent Pools > Default > New Agent
3. Select: Linux > x64
4. Copy the download URL and run on server:
```bash
cd /home/agent0
mkdir myagent && cd myagent
wget [PASTE_DOWNLOAD_URL_HERE]
tar zxvf vsts-agent-linux-x64-*.tar.gz
```

#### Step 2: Install Dependencies
```bash
sudo ./bin/installdependencies.sh
```

#### Step 3: Generate PAT Token
1. In Azure DevOps: User Settings > Personal Access Tokens
2. New Token with scope: Agent Pools (read, manage)
3. Copy the generated token

#### Step 4: Configure Agent
```bash
./config.sh
```
**Configuration Values:**
- Server URL: `https://dev.azure.com/hana-x`
- Authentication type: `PAT`
- Personal access token: `[Your generated PAT]`
- Agent pool: `Default`
- Agent name: `hx-devops-agent`
- Work folder: `_work`

#### Step 5: Install as Service
```bash
sudo ./svc.sh install agent0
sudo ./svc.sh start
sudo ./svc.sh status
```

#### Step 6: Verify
- Check in Azure DevOps > Agent Pools
- Agent should appear as "Online"

### Integration with CX Infrastructure:
The agent will enable Azure Pipelines to:
- Deploy to all 9 CX R&D servers
- Integrate with Jenkins workflows
- Use Terraform for infrastructure provisioning
- Execute Ansible playbooks for configuration management

### Troubleshooting:
- If agent offline: Check `sudo ./svc.sh status`
- View logs: `tail -f ~/myagent/_diag/Agent_*.log`
- Restart: `sudo ./svc.sh restart`
