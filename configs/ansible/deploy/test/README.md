# Testing Server Deployment

Deploys the CX-Test server under the `test_servers` inventory group with all automated testing tools preinstalled.

## File
- `deploy-test-server.yml`

## Inventory Group
- `test_servers`

## Prerequisites
- `common`, `python_env`, and `testing_tools` roles
- Script: `/opt/citadel/test_env_check.sh` must exist and be executable

## Example Run
```bash
ansible-playbook -i inventory/main.yaml deploy-test-server.yml
```

## Notes
- Test framework includes pytest, Playwright, Selenium, Locust
- Results and reports are stored under `/opt/citadel/testing/`
- Multiple testing framework ports opened (8089, 4444, 9323, 8080)

## Configuration
The playbook references variables from:
- `group_vars/test_servers/vars.yml`
- Test target endpoints for API Gateway and Web UI

## Testing Frameworks
- **pytest**: Python unit and integration testing
- **Playwright**: Browser automation and E2E testing  
- **Selenium**: Web application testing with Grid support
- **Locust**: Performance and load testing

## Test Targets
- API Gateway: `http://192.168.10.39:8000`
- Web Interface: `http://192.168.10.38:3000`

## Post-Deployment
- Service status available at `/opt/citadel/deployment_status.txt`
- JSON deployment report in `/tmp/test_deployment_*.json`
- Test results directory: `/opt/citadel/testing/`
- Locust Web UI: `http://<server_ip>:8089`
- Selenium Grid: `http://<server_ip>:4444`
- Health check script: `/opt/citadel/test_env_check.sh`
