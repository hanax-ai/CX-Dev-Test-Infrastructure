# Citadel Web UI Ansible Role

**Role Name:** `citadel_web_ui`  
**Target Host:** `hx-web-server` (192.168.10.38)  
**Frontend Port:** 3000 (proxied to 80/443)  
**Stack:** Node.js + Svelte + PM2 + Clerk + Nginx  
**Deploys:** `/opt/citadel/web-ui`

## Purpose

This role installs and configures the Citadel Web Interface using a custom Svelte frontend, integrated Clerk authentication, and backend API routing via Nginx. The service is managed by `pm2` and deployed under strict CX standards.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Citadel Web UI                           │
│                 (192.168.10.38:3000)                       │
├─────────────────────────────────────────────────────────────┤
│  Frontend: Custom Svelte Components                        │
│  • ClerkAuth.svelte - Authentication UI                    │
│  • CitadelChat.svelte - Chat Interface                     │
│  • RAGInterface.svelte - Document Search                   │
│  • citadel-theme.css - Custom Styling                      │
├─────────────────────────────────────────────────────────────┤
│  Backend Integration:                                       │
│  • API Gateway (192.168.10.39:8000) - LLM Services        │
│  • PostgreSQL (192.168.10.35:5432) - Session Storage      │
│  • Redis (192.168.10.35:6379) - Cache & Real-time         │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure:                                           │
│  • PM2 Process Manager - Service Management                │
│  • Nginx Reverse Proxy - SSL/TLS & Load Balancing         │
│  • Node.js {{ nodejs_version }} - Runtime Environment     │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

- **Clerk Authentication Integration** - Frontend + backend session management
- **Custom Svelte Components** - Modular, reusable UI components
- **API Gateway Integration** - Seamless LLM and RAG service access
- **Nginx Reverse Proxy** - SSL termination and load balancing
- **PM2 Process Management** - Production-grade service management
- **Comprehensive Monitoring** - Health checks, logging, and metrics
- **Session Management** - PostgreSQL + Redis backend
- **Feature Flags** - Configurable functionality via `defaults/main.yml`
- **Production Ready** - Follows CX deployment standards

## Service Management

### Service Name
`citadel_web_ui.service` (PM2-managed)

### Key Commands
```bash
# Service status
systemctl status citadel_web_ui.service

# PM2 management
sudo -u www-data pm2 status {{ app_name }}
sudo -u www-data pm2 logs {{ app_name }}
sudo -u www-data pm2 restart {{ app_name }}

# Health check
/usr/local/bin/web_ui_health_check.sh

# Nginx management
systemctl status nginx
systemctl reload nginx
```

## Configuration

### Primary Configuration File
`/opt/CX-Dev-Test-Infrastructure/configs/ansible/roles/citadel_web_ui/defaults/main.yml`

### Key Configuration Sections

#### Application Settings
```yaml
app_name: "citadel_web_ui"
app_version: "1.0.0"
app_port: 3000
app_directory: "/opt/citadel/web-ui"
```

#### API Gateway Integration
```yaml
api_gateway:
  host: "192.168.10.39"
  port: 8000
  base_url: "http://192.168.10.39:8000"
  endpoints:
    chat: "/api/v1/chat"
    rag: "/api/v1/rag"
    auth: "/api/v1/auth"
    models: "/api/v1/models"
```

#### Clerk Authentication
```yaml
clerk_config:
  frontend_api: "{{ vault_clerk_frontend_api }}"
  publishable_key: "{{ vault_clerk_publishable_key }}"
  secret_key: "{{ vault_clerk_secret_key }}"
  jwt_key: "{{ vault_clerk_jwt_key }}"
```

#### Feature Flags
```yaml
features:
  enable_rag: true
  enable_document_upload: true
  enable_conversation_history: true
  enable_model_switching: true
  enable_admin_panel: false
```

#### Branding and Styling
```yaml
branding:
  primary_color: "#1976d2"
  secondary_color: "#dc004e"
  logo_url: "/assets/citadel-logo.svg"
  favicon_url: "/assets/favicon.ico"
  custom_css: true
```

## Templates

### Core Templates
- **`package.json.j2`** - Node.js package configuration
- **`.env.j2`** - Environment variables
- **`config.js.j2`** - Application configuration
- **`ecosystem.config.js.j2`** - PM2 process configuration
- **`nginx_web_ui.conf.j2`** - Nginx reverse proxy configuration

### Svelte Components
- **`ClerkAuth.svelte.j2`** - Authentication component with Clerk integration
- **`CitadelChat.svelte.j2`** - Chat interface with LLM integration
- **`RAGInterface.svelte.j2`** - Document upload and RAG query interface

### Styling and Assets
- **`citadel-theme.css.j2`** - Custom CSS theme with design system

### Monitoring and Maintenance
- **`health_check.sh.j2`** - Comprehensive health monitoring script
- **`logrotate.conf.j2`** - Log rotation configuration

## Dependencies

### Infrastructure Dependencies
- **API Gateway** (192.168.10.39) - Chat, RAG, and model services
- **PostgreSQL** (192.168.10.35) - Session and user data storage
- **Redis** (192.168.10.35) - Caching and real-time features

### System Dependencies
- Node.js {{ nodejs_version }}
- npm/yarn package manager
- PM2 process manager
- Nginx web server
- OpenSSL (for TLS)

### External Services
- **Clerk.com** - Authentication provider
- **OpenAI/LLM APIs** - Via API Gateway integration

## Deployment

### Prerequisites
1. Target server accessible via SSH
2. DNS/networking configured for 192.168.10.38
3. Clerk account and API keys configured
4. API Gateway deployed and operational
5. Database services available

### Deployment Command
```bash
cd /opt/CX-Dev-Test-Infrastructure/configs/ansible
ansible-playbook -i inventory/main.yaml deploy/web/deploy-web-servers.yml
```

### Post-Deployment Validation
```bash
# Check service status
systemctl status citadel_web_ui.service

# Verify web interface
curl -f http://192.168.10.38:3000

# Run health check
/usr/local/bin/web_ui_health_check.sh

# Check logs
sudo -u www-data pm2 logs citadel_web_ui
```

## Monitoring and Logging

### Log Locations
- **Application Logs**: `{{ app_directory }}/logs/`
- **PM2 Logs**: `/home/www-data/.pm2/logs/`
- **Nginx Logs**: `/var/log/nginx/web-ui.*`
- **System Logs**: `journalctl -u citadel_web_ui.service`

### Health Monitoring
The role includes a comprehensive health check script at `/usr/local/bin/web_ui_health_check.sh` that monitors:

- Service and PM2 process status
- HTTP endpoint availability
- API Gateway connectivity
- Database connectivity
- System resources (disk, memory)
- SSL certificate validity
- Log file sizes

### Metrics and Alerting
- Health check endpoint: `http://192.168.10.38:3000/health`
- Metrics endpoint: `http://192.168.10.38:3000/metrics`
- Integration with Prometheus/Grafana (if configured)

## Security

### Authentication
- **Clerk Integration** - Modern authentication provider
- **JWT Session Management** - Secure token-based auth
- **CSRF Protection** - Cross-site request forgery protection
- **Rate Limiting** - API endpoint protection

### Network Security
- **CORS Configuration** - Restricted cross-origin access
- **TLS/SSL Ready** - Nginx SSL termination
- **Internal Network** - Restricted to 192.168.10.0/24
- **Firewall Rules** - UFW configuration included

### Data Protection
- **Secure Cookies** - HTTPOnly, Secure, SameSite
- **Environment Variables** - Sensitive data protection
- **Session Encryption** - Encrypted session storage

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
systemctl status citadel_web_ui.service

# Check PM2 status
sudo -u www-data pm2 status

# Check logs
sudo -u www-data pm2 logs citadel_web_ui --lines 50
```

#### Connection Issues
```bash
# Test local connectivity
curl -v http://127.0.0.1:3000

# Check nginx configuration
nginx -t
systemctl status nginx

# Check firewall
sudo ufw status verbose
```

#### Authentication Problems
```bash
# Verify Clerk configuration
grep -E "CLERK_|clerk_" {{ app_directory }}/.env

# Check API Gateway connectivity
curl -v {{ api_gateway.base_url }}/health
```

### Debug Mode
Enable debug logging by setting:
```yaml
# In defaults/main.yml
development:
  debugMode: true
```

### Recovery Procedures

#### Service Recovery
```bash
# Full service restart
systemctl restart citadel_web_ui.service

# PM2 restart only
sudo -u www-data pm2 restart citadel_web_ui

# Clear PM2 logs
sudo -u www-data pm2 flush citadel_web_ui
```

#### Database Connection Issues
```bash
# Test PostgreSQL connectivity
psql -h 192.168.10.35 -U citadel_web -d citadel_sessions -c "SELECT 1;"

# Check Redis connectivity
redis-cli -h 192.168.10.35 ping
```

## Development

### AG UI Development Roadmap
This role supports the active development of AG UI components and is designed to accommodate:

- Component hot-reloading during development
- Custom Svelte component integration
- Theme customization and branding
- Feature flag management
- API integration testing

### Local Development
For development purposes, the role can be configured with:
```yaml
development:
  hotReload: true
  sourceMap: true
  debugMode: true
```

## Maintenance

### Updates and Patches
- **Node.js Updates**: Modify `nodejs_version` in defaults
- **Dependency Updates**: Update `package.json.j2` template
- **Component Updates**: Modify Svelte component templates
- **Configuration Changes**: Update `defaults/main.yml`

### Backup Considerations
- **Application Code**: Version controlled (Git)
- **Configuration**: Managed by Ansible
- **User Data**: Stored in PostgreSQL (backup separately)
- **Session Data**: Stored in Redis (ephemeral)

## Support

### Architecture Documentation
- **Primary**: `/opt/CX-Dev-Test-Infrastructure/CX-Documents/CX-RnD-Infrastructure-Architecture.md`
- **Web Server Config**: `/opt/CX-Dev-Test-Infrastructure/CX-Documents/CX-Web-Server-Configuration.md`

### Deployment Standards
- **Best Practices**: `/opt/CX-Dev-Test-Infrastructure/.github/instructions/Deployment-Best-Practices.instructions.md`
- **Troubleshooting**: Follow CX Infrastructure diagnostic procedures

---

**Last Updated**: {{ ansible_date_time.iso8601 }}  
**Deployed By**: Citadel Infrastructure Automation  
**Compliance**: CX R&D Infrastructure Standards
