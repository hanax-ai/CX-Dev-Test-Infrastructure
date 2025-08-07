# Dependency Management

## Requirements Structure

This project uses a centralized dependency management approach:

- **Main requirements**: `configs/ansible/deploy/api-gateway/requirements.txt`
- **Gateway app requirements**: References main file using `-r ../requirements.txt`

## Pinned Versions

All dependencies are pinned to specific versions to ensure reproducible builds:

```
fastapi==0.104.1       # Web framework
uvicorn==0.24.0        # ASGI server  
httpx==0.25.2          # HTTP client
pydantic==2.7.4        # Data validation
PyYAML==6.0.2          # YAML parsing
```

## Benefits

- **No version drift**: Pinned versions prevent overnight breaking changes
- **Single source of truth**: One requirements file to maintain
- **Consistent environments**: Same versions across dev/test/prod
- **Easier updates**: Update versions in one place

## Installation

```bash
# Install for WebUI gateway
cd configs/ansible/deploy/api-gateway
pip install -r requirements.txt

# Install for main gateway (automatically includes main requirements)
cd configs/ansible/deploy/api-gateway/gateway_app  
pip install -r requirements.txt
```
