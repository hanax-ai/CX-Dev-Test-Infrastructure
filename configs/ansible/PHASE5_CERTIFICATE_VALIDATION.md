# Phase 5 Certificate Validation Strategy

## Overview
The Phase 5 deployment playbook includes intelligent certificate validation handling for internal services that may use self-signed certificates.

## Configuration Variables

### `internal_ca_available`
- **Type**: Boolean
- **Default**: `false`
- **Description**: Set to `true` if your organization has deployed a Certificate Authority (CA) bundle that includes the signing certificates for your internal services.

### `validate_internal_certs`
- **Type**: Boolean
- **Derived**: `{{ internal_ca_available | default(false) }}`
- **Description**: Controls whether certificate validation is performed when checking internal service connectivity.

## Behavior

### When `internal_ca_available: false` (Default)
- Certificate validation is **disabled** for internal service connectivity checks
- This prevents false negatives when Phase 4 LLM servers use self-signed certificates
- Services are marked as ONLINE/OFFLINE based on HTTP response, not certificate validity
- ⚠️ **Security Note**: This is appropriate for internal networks but should not be used for external endpoints

### When `internal_ca_available: true`
- Certificate validation is **enabled** for all TLS connections
- Requires that the CA bundle includes certificates for all internal services
- Provides full certificate chain validation for enhanced security

## Implementation

The playbook uses this approach in the Phase 4 dependency check:

```yaml
- name: Verify Phase 4 LLM server connectivity
  uri:
    url: "{{ (tls_enabled | default(false)) | ternary('https', 'http') }}://{{ item.ip }}:{{ item.port }}/api/tags"
    method: GET
    timeout: 10
    validate_certs: "{{ validate_internal_certs }}"
  loop: "{{ llm_servers }}"
  register: llm_connectivity
  failed_when: false
```

## Deployment Scenarios

### Scenario 1: Development/Testing Environment
- Use default settings (`internal_ca_available: false`)
- Self-signed certificates are acceptable
- Focus on functionality rather than certificate security

### Scenario 2: Production Environment with Internal CA
- Set `internal_ca_available: true`
- Deploy CA bundle to all servers
- Full certificate validation for enhanced security

### Scenario 3: Production with External Certificates
- Set `internal_ca_available: true`
- Use certificates from public CA (Let's Encrypt, etc.)
- Standard certificate validation applies

## Security Considerations

1. **Internal Networks**: Disabling certificate validation is acceptable within trusted internal networks
2. **External Exposure**: Never disable certificate validation for externally accessible services
3. **Certificate Management**: Consider implementing automated certificate deployment for production
4. **Monitoring**: Monitor certificate expiration even when validation is disabled

## Troubleshooting

### Issue: Phase 4 services show as OFFLINE despite being functional
**Cause**: Self-signed certificates with validation enabled
**Solution**: Set `internal_ca_available: false` or deploy appropriate CA bundle

### Issue: Certificate warnings in logs
**Cause**: Expected behavior when using self-signed certificates
**Solution**: This is normal - warnings inform about the validation strategy

## Future Enhancements

1. **Automatic CA Detection**: Implement automatic detection of available CA bundles
2. **Per-Service Configuration**: Allow different validation strategies per service
3. **Certificate Monitoring**: Add certificate expiration monitoring tasks
