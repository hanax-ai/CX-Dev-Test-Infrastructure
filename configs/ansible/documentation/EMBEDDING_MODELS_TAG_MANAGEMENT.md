# Embedding Models Tag Management

## Overview
This document explains the importance of using explicit model tags for reproducible deployments and provides guidance on maintaining model versions.

## Why Explicit Tags Matter

### Problem with Implicit "latest" Tags
When model names are specified without explicit tags (e.g., `mxbai-embed-large`), Ollama automatically pulls the `latest` tag. This creates several issues:

1. **Non-Deterministic Deployments**: Different deployment runs may pull different model versions
2. **Inconsistent Environments**: Development, staging, and production may have different model versions
3. **Difficult Rollbacks**: No clear way to identify which version was previously deployed
4. **Supply Chain Risk**: Unexpected model updates could introduce compatibility issues

### Benefits of Explicit Tags
Using explicit tags (e.g., `mxbai-embed-large:335m`) provides:

1. **Reproducible Deployments**: Same model version across all environments
2. **Version Control**: Clear tracking of model versions in infrastructure code
3. **Controlled Updates**: Explicit decisions about when to update models
4. **Rollback Capability**: Easy identification of previous working versions

## Current Model Configuration

### Embedding Models with Explicit Tags
```yaml
embedding_models:
  - name: "mxbai-embed-large:335m"
    size: "334M"
    description: "High-quality multilingual embeddings"
  - name: "nomic-embed-text:v1.5"
    size: "137M" 
    description: "Efficient text embeddings"
  - name: "all-minilm:33m"
    size: "23M"
    description: "Lightweight sentence embeddings"
```

### Tag Selection Rationale
- **mxbai-embed-large:335m**: Stable release with good performance/size balance
- **nomic-embed-text:v1.5**: Latest stable version with improved performance
- **all-minilm:33m**: Lightweight version suitable for resource-constrained scenarios

## Files Updated for Tag Consistency

1. **`roles/deploy_embedding_models/defaults/main.yml`**
   - Core model definitions with explicit tags

2. **`phase5-inventory.yml`**
   - Orchestration server model configuration
   - Updated: `nomic-embed-text` → `nomic-embed-text:v1.5`

3. **`roles/api-gateway/defaults/main.yml`**
   - API Gateway embedding model configuration
   - Updated: `nomic-embed-text` → `nomic-embed-text:v1.5`

## Model Update Process

### 1. Research New Versions
- Check Ollama model registry for new releases
- Review release notes for compatibility and performance changes
- Test new versions in development environment

### 2. Update Configuration
```yaml
# Before
- name: "mxbai-embed-large"

# After  
- name: "mxbai-embed-large:335m"
```

### 3. Validate Changes
```bash
# Syntax check
ansible-playbook --syntax-check deploy-embeddings.yml

# Test deployment in development
ansible-playbook -i dev-inventory.yml deploy-embeddings.yml
```

### 4. Deploy to Environments
- Development → Staging → Production
- Validate functionality at each stage
- Monitor performance and compatibility

## Monitoring and Maintenance

### Version Tracking
Keep track of model versions deployed across environments:

```bash
# Check installed models
ollama list

# Verify specific model version
curl -X POST http://localhost:11434/api/show \
  -d '{"name": "mxbai-embed-large:335m"}'
```

### Performance Monitoring
- Monitor embedding generation times
- Track memory usage patterns
- Validate output quality with test datasets

### Update Schedule
- **Patch Updates**: Apply immediately if security-related
- **Minor Updates**: Quarterly review and testing
- **Major Updates**: Annual evaluation with thorough testing

## Best Practices

### 1. Tag Format Standards
- Use semantic versioning when available (e.g., `v1.5`)
- Use size indicators for clarity (e.g., `335m`, `7b`)
- Avoid generic tags like `latest` or `stable`

### 2. Testing Strategy
- Test all models in development before production deployment
- Validate backward compatibility with existing embeddings
- Performance benchmark against previous versions

### 3. Documentation
- Document tag selection rationale
- Maintain changelog of model updates
- Record performance impact of version changes

### 4. Rollback Planning
- Keep previous version tags documented
- Test rollback procedures
- Have automated rollback scripts ready

## Troubleshooting

### Tag Not Found Error
```
Error: pull model manifest: file does not exist
```
**Solution**: Verify tag exists in Ollama registry or update to available tag

### Version Mismatch
```
Error: model version incompatible with existing embeddings
```
**Solution**: Review migration path or maintain separate model instances

### Performance Degradation
**Solution**: 
1. Compare benchmarks with previous version
2. Check resource utilization
3. Consider reverting to previous stable version

## Security Considerations

### Model Integrity
- Verify model checksums when possible
- Use trusted model sources
- Monitor for unexpected model behavior

### Access Control
- Restrict model update permissions
- Audit model deployment changes
- Implement approval workflow for production updates

## Future Enhancements

1. **Automated Version Checking**: Scripts to check for new model versions
2. **Performance Benchmarking**: Automated performance comparison between versions
3. **Gradual Rollout**: Blue-green deployment for model updates
4. **Compatibility Matrix**: Track compatibility between model versions and applications
