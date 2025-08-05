# Development Server Deployment

This playbook provisions the CX-Dev server (`development_servers` group) for source-level Python/Node-based development, with Docker and VS Code.

## File
- `deploy-dev-server.yml`

## Inventory Group
- `development_servers`

## Prerequisites
- `common`, `python_env`, and `development_tools` roles
- Script: `/opt/citadel/dev_env_check.sh` must exist and be executable

## Example Run
```bash
ansible-playbook -i inventory/main.yaml deploy-dev-server.yml
```

## Notes
- Exposes code-server on port 8443 (with password)
- Creates a summary file under `/opt/citadel/deployment_status.txt`
- Development ports (3000, 5000, 8080, 9000) opened for local development

## Configuration
The playbook references variables from:
- `group_vars/development_servers/vars.yml`
- Code server configuration and authentication settings

## Development Tools
- Python 3.11+ with virtual environments
- Node.js 20+ with npm/yarn
- Git for version control
- Docker for containerization
- Code Server (VS Code in browser)

## Post-Deployment
- Service status available at `/opt/citadel/deployment_status.txt`
- JSON deployment report in `/tmp/dev_deployment_*.json`
- Code Server IDE: `http://<server_ip>:8443`
- Health check script: `/opt/citadel/dev_env_check.sh`
