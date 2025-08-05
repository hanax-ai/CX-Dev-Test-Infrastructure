# LLM Server 02 Security Enhancements

## Overview
The LLM Server 02 deployment has been enhanced with critical security and reliability improvements based on CodeRabbit analysis.

## Security Improvements

### 1. Installer Integrity Verification
**Issue**: Downloading and executing remote scripts without verification poses supply chain security risks.

**Solution**: Added SHA256 checksum verification for the Ollama installer:

```yaml
vars:
  # Security: SHA256 checksum for installer integrity verification
  ollama_install_sha256: "9f5f4c4ed21821ba9b847bf3607ae75452283276cd8f52d2f2b38ea9f27af344"

tasks:
  - name: 8. Download Ollama installer with integrity verification
    get_url:
      url: https://ollama.com/install.sh
      dest: /tmp/ollama_install.sh
      checksum: "sha256:{{ ollama_install_sha256 }}"
```

**Maintenance**: When Ollama releases new versions, update the `ollama_install_sha256` variable with the new checksum.

### 2. How to Update Checksum
When a new Ollama version is released:

1. **Fetch the new checksum**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sha256sum
   ```

2. **Update the playbook variable**:
   ```yaml
   ollama_install_sha256: "NEW_CHECKSUM_HERE"
   ```

3. **Test the deployment** on a development server before production.

## Reliability Improvements

### 1. Safe Disk Space Display
**Issue**: `disk_space.stdout_lines[1]` could cause index errors on single-line outputs.

**Solution**: Use safe array access with default fallback:
```yaml
msg: "Available disk space: {{ (disk_space.stdout_lines | last) | default('unknown') }}"
```

### 2. Consistent Model Directory Configuration
**Issue**: Service configuration and directory creation used different paths and ownership:
- Service: `/var/lib/ollama/models` (ollama user)  
- Created: `/opt/ai_models` (agent0 user)

**Solution**: Unified configuration using variables:
```yaml
vars:
  model_dir: "/opt/ai_models"
  ollama_service_user: "ollama"

# Service configuration
Environment="OLLAMA_MODELS={{ model_dir }}"

# Directory creation
file:
  path: "{{ model_dir }}"
  owner: "{{ ollama_service_user }}"
  group: "{{ ollama_service_user }}"
```

## Configuration Details

### Model Directory
- **Path**: `/opt/ai_models`
- **Owner**: `ollama:ollama`
- **Permissions**: `0755`
- **Service Access**: Configured in systemd ReadWritePaths

### Security Hardening
The service includes comprehensive security measures:
- `NoNewPrivileges=true` - Prevents privilege escalation
- `PrivateTmp=true` - Isolated temporary directory
- `ProtectSystem=strict` - Read-only filesystem protection
- `ProtectHome=true` - Home directory protection
- `ReadWritePaths` - Explicit write access only to required directories

## Verification Steps

After deployment, verify the configuration:

1. **Check service status**:
   ```bash
   systemctl status ollama
   ```

2. **Verify model directory ownership**:
   ```bash
   ls -la /opt/ai_models
   ```

3. **Test API connectivity**:
   ```bash
   curl http://localhost:11434/api/version
   ```

4. **Check service configuration**:
   ```bash
   systemctl cat ollama
   ```

## Security Considerations

1. **Checksum Updates**: Always verify new checksums from trusted sources
2. **Network Security**: The service binds to all interfaces (0.0.0.0) for internal network access
3. **File Permissions**: Strict file permissions prevent unauthorized access
4. **Service Isolation**: Systemd security features provide process isolation

## Troubleshooting

### Checksum Mismatch
If the installer download fails due to checksum mismatch:
1. Verify the current checksum: `curl -fsSL https://ollama.com/install.sh | sha256sum`
2. Compare with the configured checksum
3. Update the playbook if Ollama has released a new version
4. Ensure no man-in-the-middle attacks are occurring

### Model Directory Issues  
If models are not accessible:
1. Check directory ownership: `ls -la /opt/ai_models`
2. Verify service configuration: `systemctl cat ollama | grep OLLAMA_MODELS`
3. Check service logs: `journalctl -u ollama -f`

### Permission Errors
If the service cannot write to the model directory:
1. Verify ownership: `chown -R ollama:ollama /opt/ai_models`
2. Check SELinux contexts if applicable
3. Verify systemd ReadWritePaths configuration
