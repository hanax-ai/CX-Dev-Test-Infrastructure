---
applyTo: '**'
---

# CX Infrastructure Deployment Best Practices

This document outlines the essential guidelines and procedures for deploying and managing the CX R&D Infrastructure. All deployment activities must strictly adhere to these practices to ensure reliability, security, and maintainability.

## 1. Guiding Principles

### 1.1 Automation-First Approach
- **All infrastructure changes must be implemented via Ansible playbooks**
- Manual changes on servers are strictly prohibited except for emergency troubleshooting
- Infrastructure as Code (IaC) principles must be followed consistently

### 1.2 Production Readiness Standard
- **Every component must be deployed as a robust, managed service suitable for production**
- High availability and fault tolerance must be considered in all deployments
- All services must include proper monitoring, logging, and alerting

## 2. Ansible Playbook Development Standards

### 2.1 Idempotency Requirements
- **All playbooks must be safely re-runnable without causing errors or unintended changes**
- Use appropriate Ansible modules that support idempotent operations
- Test playbook idempotency before deployment to production

### 2.2 Variable Management
- **Use descriptive variables, not hardcoded values**
- Define all configurable values in the `vars` section for clarity and maintainability
- Use group and host variables appropriately in the inventory structure
- Follow naming convention: `service_name_variable_name` (e.g., `api_gateway_port`)

### 2.3 Environment Isolation
- **Each application or service must be installed into its own dedicated Python virtual environment**
- Follow standard naming conventions: `/opt/<service_name>/env`
- Example: API Gateway → `/opt/api_gateway/env`
- Prevent dependency conflicts between services

### 2.4 Service Management
- **All long-running applications must be managed by systemd services**
- Create proper systemd unit files with appropriate dependencies
- Configure services for automatic startup and restart on failure
- Use standardized service naming: `cx-<service-name>.service`

### 2.5 Module Usage Best Practices
- **Prefer built-in Ansible modules over shell commands**
- Use `uri` instead of `curl`, `get_url` instead of `wget`
- Improves error handling, logging, and idempotency
- Only use shell/command modules when no appropriate module exists

## 3. Validation and Testing Procedures

### 3.1 Pre-Deployment Validation
- **Every deployment must be preceded by pre-flight checks**
- Execute `ansible/playbooks/preflight-checks.yml` to validate server state
- Verify all prerequisites (CUDA, Python, SSH access, disk space)
- Address all identified issues before proceeding with deployment

### 3.2 Post-Deployment Validation
- **Every playbook must conclude with comprehensive validation tasks**
- Verify service is running: `systemctl is-active <service_name>`
- Test API endpoints and functionality
- Validate integration with dependent services
- Document validation results in deployment logs

### 3.3 Testing Infrastructure
- **Utilize the dedicated CX-Test Server (192.168.10.34) for comprehensive testing**
- Use pytest framework for unit and integration tests
- Use Playwright for end-to-end web interface testing
- Run full test suite before promoting to production servers

## 4. CI/CD Pipeline Standards (Jenkins)

### 4.1 Deployment Execution
- **All production deployments must be executed via Jenkins pipeline**
- Use the official Jenkins server for deployment orchestration
- Maintain deployment approval workflow for production changes
- Log all deployment activities with timestamps and user attribution

### 4.2 Jenkins Best Practices
- **Use `dir()` for directory changes**:
  ```groovy
  dir('ansible') {
      sh 'ansible-playbook playbooks/deploy-service.yml'
  }
  ```

- **Use `withEnv` for environment activation**:
  ```groovy
  withEnv(["PATH+PYTHON=/opt/service_name/env/bin"]) {
      sh 'python manage.py migrate'
  }
  ```

### 4.3 Pipeline Security
- Store sensitive credentials in Jenkins credential store
- Use SSH keys for server access, never passwords
- Implement proper RBAC for pipeline access

## 5. Security and Access Management

### 5.1 SSH Key Management
- **All servers must use SSH key authentication**
- AI servers use RSA keys (`~/.ssh/id_rsa`)
- Phase 5 servers use Ed25519 keys (`~/.ssh/id_ed25519`)
- Regularly rotate SSH keys and update inventory

### 5.2 User Access Standards
- **Use `agent0` user for all automated deployments**
- Configure passwordless sudo for deployment user
- Implement proper user access controls and auditing

### 5.3 Network Security
- Configure UFW firewall rules appropriately
- Restrict service access to required networks only
- Document all firewall rules and port requirements

## 6. Monitoring and Logging

### 6.1 Service Monitoring
- **All services must include health check endpoints**
- Configure systemd service monitoring and automatic restart
- Implement proper log rotation and retention policies
- Use structured logging formats (JSON preferred)

### 6.2 Deployment Logging
- **All deployments must generate comprehensive logs**
- Store logs in `ansible/logs/` with timestamp naming
- Include pre-flight, deployment, and validation results
- Retain deployment logs for audit and troubleshooting

## 7. Standard Troubleshooting Procedures

When a service fails, follow this diagnostic procedure on the target server:

### 7.1 Service Diagnostics
1. **Check service status**:
   ```bash
   systemctl status <service_name>
   ```

2. **Check for errors in logs**:
   ```bash
   journalctl -u <service_name> -n 100 --no-pager
   ```

3. **Check network listeners**:
   ```bash
   ss -tulpn | grep <port_number>
   ```

4. **Check firewall rules**:
   ```bash
   sudo ufw status verbose
   ```

### 7.2 Additional Diagnostics
5. **Check disk space**:
   ```bash
   df -h /opt/<service_path>
   ```

6. **Check process status**:
   ```bash
   ps aux | grep <service_name>
   ```

7. **Check GPU status** (for AI servers):
   ```bash
   nvidia-smi
   ```

8. **Verify dependencies**:
   ```bash
   systemctl list-dependencies <service_name>
   ```

## 8. Emergency Procedures

### 8.1 Service Recovery
- Always attempt to resolve issues through Ansible playbooks
- Document any manual interventions performed during emergencies
- Update playbooks to prevent future occurrences of the same issue

### 8.2 Rollback Procedures
- Maintain previous service versions for rapid rollback capability
- Test rollback procedures as part of deployment planning
- Document rollback steps for each service type

## 9. Compliance and Documentation

### 9.1 Change Documentation
- **All infrastructure changes must be documented**
- Update architecture documents when topology changes
- Maintain changelog for all deployments
- Include migration procedures for breaking changes

### 9.2 Audit Trail
- Maintain complete audit trail of all deployments
- Log user, timestamp, and change details
- Preserve deployment logs for compliance requirements

### 10. New Directories and Files
- Unless the task requires a new directory or file, do not create them.
- If a new directory or file is required, ensure it is documented in the architecture and follows the naming conventions.

### 11. Questions and Assumptions 
- For any questions or if you are unsure about a task, ask for help.
- Do not make assumptions about the task requirements.

### 12. Task Execution
- Follow the steps outlined in the task description. Do not freelance or deviate from the established steps unless explicitly instructed.
- If a task requires creating or modifying files, ensure you follow the naming conventions and directory structure.
- If you discover new tasks are required to complete the task, inform the user and do not proceed with the task until you have confirmation.
- It is ok to make observations and recommendations, but do not make changes without explicit instructions.

### 13. Sudo Access
- Sudo access credentials must be managed through secure credential stores
- Contact system administrators for sudo access procedures
- Never store passwords in documentation or version control