# Group Variables Structure Mapping
# CX Infrastructure - Canonical Inventory Integration
# Updated: 2025-08-04

## Group Variables Directory Structure

The following structure aligns with the canonical `main.yaml` inventory:

| Group Name in `main.yaml`    | Group Vars Path                              | Servers Included                    |
|-------------------------------|-----------------------------------------------|-------------------------------------|
| `database_servers`            | `group_vars/database_servers/vars.yml`       | hx-sql-database-server             |
| `vector_db_servers`           | `group_vars/vector_db_servers/vars.yml`      | hx-vector-db-server                |
| `api_gateway_servers`         | `group_vars/api_gateway_servers/vars.yml`    | hx-api-gateway-server              |
| `web_servers`                 | `group_vars/web_servers/vars.yml`            | hx-web-server                      |
| `orchestration_servers`       | `group_vars/orchestration_servers/vars.yml`  | hx-orchestration-server            |
| `llm_servers`                 | `group_vars/llm_servers/vars.yml`            | hx-llm-server-01, hx-llm-server-02 |
| `devops_servers`              | `group_vars/devops_servers/vars.yml`         | hx-dev-ops-server                  |
| `development_servers`         | `group_vars/development_servers/vars.yml`    | hx-dev-server                      |
| `test_servers`                | `group_vars/test_servers/vars.yml`           | hx-test-server                     |
| `metrics_servers`             | `group_vars/metrics_servers/vars.yml`        | hx-metrics-server                  |

## Configuration Categories

### Infrastructure Services
- **Database**: PostgreSQL, Redis, monitoring, backup systems
- **Vector DB**: Qdrant, storage optimization, backup systems
- **API Gateway**: FastAPI, Nginx, load balancing, SSL/TLS, rate limiting
- **Web**: OpenWebUI, Node.js, Nginx, Clerk authentication
- **Orchestration**: Ollama, embedding models, CUDA configuration

### AI/ML Services
- **LLM Servers**: Ollama, chat models, instruct models, GPU configuration
- **Embedding**: Model management, performance optimization

### Development & Operations
- **DevOps**: Jenkins, Ansible, Terraform, CI/CD pipelines
- **Development**: Code Server, development tools, testing frameworks
- **Testing**: pytest, Playwright, performance testing, QA automation
- **Metrics**: Prometheus, Grafana, Node Exporter, alerting

## Variable Management Best Practices

1. **Sensitive Data**: Use Ansible Vault in `group_vars/all/vault.yml`
2. **Environment-Specific**: Override in host_vars if needed
3. **Service Ports**: Standardized across groups
4. **SSL/TLS**: Consistent certificate paths and configuration
5. **Monitoring**: Enabled by default with standardized exporters

## Integration with Canonical Inventory

This structure directly supports the canonical `main.yaml` inventory:
- Group names match exactly
- Variable inheritance follows Ansible precedence
- Service definitions align with inventory metadata
- Monitoring targets include all infrastructure servers
