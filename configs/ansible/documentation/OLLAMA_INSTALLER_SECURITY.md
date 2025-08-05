# Ollama Installer Security - Checksum Verification

## Overview

The orchestration server deployment uses checksum verification to ensure the integrity of the Ollama installer script, preventing supply chain attacks and code injection.

## Current Checksum

**Last Updated**: 2025-08-04  
**Current SHA256**: `9f5f4c4ed21821ba9b847bf3607ae75452283276cd8f52d2f2b38ea9f27af344`

## Updating the Checksum

When Ollama releases a new installer version, update the checksum:

### 1. Get New Checksum
```bash
curl -fsSL https://ollama.com/install.sh | sha256sum
```

### 2. Update Playbook Variable
Edit `configs/ansible/deploy-orchestration-server.yml`:
```yaml
vars:
  # Update this checksum when Ollama releases new installer
  ollama_installer_checksum: "sha256:NEW_CHECKSUM_HERE"
```

### 3. Update Documentation
Update this file with:
- New checksum value
- Current date
- Any relevant notes about the Ollama version

## Security Benefits

### Supply Chain Protection
- **Prevents CDN compromise**: Detects if installer is modified at source
- **Blocks MITM attacks**: Ensures downloaded script matches expected version
- **Validates integrity**: Confirms no corruption during download

### Deployment Safety
- **Fails fast**: Deployment stops if checksum doesn't match
- **Audit trail**: Checksum value recorded in deployment logs
- **Version control**: Checksum changes tracked in git history

## Troubleshooting

### Checksum Mismatch Error
If deployment fails with checksum mismatch:

1. **Check if Ollama updated installer**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sha256sum
   ```

2. **Compare with expected checksum** in playbook variables

3. **If checksums differ**:
   - Verify the new checksum is legitimate (check Ollama releases)
   - Update the playbook variable with new checksum
   - Document the change in git commit

4. **If security concern**:
   - Do not update checksum without verification
   - Investigate potential compromise
   - Contact security team if needed

### Manual Verification
To manually verify installer integrity:
```bash
# Download installer
curl -fsSL https://ollama.com/install.sh -o /tmp/test-install.sh

# Check checksum
sha256sum /tmp/test-install.sh

# Compare with expected value
echo "9f5f4c4ed21821ba9b847bf3607ae75452283276cd8f52d2f2b38ea9f27af344  /tmp/test-install.sh" | sha256sum -c
```

## Version History

| Date | Checksum | Notes |
|------|----------|-------|
| 2025-08-04 | 9f5f4c4ed21821ba9b847bf3607ae75452283276cd8f52d2f2b38ea9f27af344 | Initial implementation with checksum verification |

## Maintenance

- **Review quarterly**: Check for Ollama installer updates
- **Monitor security advisories**: Watch for Ollama security announcements  
- **Update promptly**: Apply new checksums when legitimate updates available
- **Document changes**: Record all checksum updates with justification
