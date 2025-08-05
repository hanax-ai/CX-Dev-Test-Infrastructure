# Web Server Deployment (OpenWebUI)

Deploys the OpenWebUI frontend to all `web_servers`. This setup includes environment configuration, Python/Node setup, and UI service launch.

## File
- `deploy-web-server.yml`

## Inventory Group
- `web_servers`

## Prerequisites
- `common` and `web_interface` roles
- Ollama must be reachable via `OLLAMA_BASE_URL`
- API Gateway service must be running (192.168.10.39)

## Example Run
```bash
ansible-playbook -i inventory/main.yaml deploy-web-server.yml
```

## Notes
- Port 3000 is used for the web interface
- Metadata is logged to `/opt/citadel/deployment_status.txt`
- Clerk authentication integration available

## Configuration
The playbook references variables from:
- `group_vars/web_servers/vars.yml`
- Clerk auth settings from vault if enabled

## Service Dependencies
- API Gateway (192.168.10.39:8000)
- Ollama LLM Service (192.168.10.29:11434)

## Post-Deployment
- Service status available at `/opt/citadel/deployment_status.txt`
- JSON deployment report in `/tmp/web_deployment_*.json`
- Web interface: `http://<server_ip>:3000`
