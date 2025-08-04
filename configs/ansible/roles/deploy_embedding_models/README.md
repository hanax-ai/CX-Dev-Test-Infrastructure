# Deploy Embedding Models Role

## Overview

This role deploys embedding models to the Ollama server on the CX orchestration server. It addresses all security and structural issues identified in the previous deployment approach.

## Features

- **Security First**: Validates server identity before deployment
- **Comprehensive Logging**: Detailed deployment logs with timestamps
- **Idempotent Operations**: Safe to run multiple times
- **Error Handling**: Robust retry logic and validation
- **Production Ready**: Full monitoring and testing capabilities

## Models Deployed

| Model Name | Size | Description |
|------------|------|-------------|
| mxbai-embed-large | 334M | High-quality multilingual embeddings |
| nomic-embed-text | 137M | Efficient text embeddings |
| all-minilm | 23M | Lightweight sentence embeddings |

## Requirements

- Ollama server must be installed and running
- CUDA-capable GPU (validated during deployment)
- Sufficient disk space for models
- Network connectivity for model downloads

## Variables

### Default Variables (`defaults/main.yml`)

```yaml
# Embedding models configuration
embedding_models:
  - name: "mxbai-embed-large"
    size: "334M"
    description: "High-quality multilingual embeddings"
  # ... additional models

# Ollama configuration
ollama_port: 11434
ollama_user: "agent0"
model_storage_path: "/usr/share/ollama/.ollama/models"

# Deployment settings
deployment_log_file: "/var/log/cx-embedding-deployment.log"
retry_attempts: 3
retry_delay: 30

# Feature flags
verify_installations: true
test_endpoints: true
```

## Security Improvements

### 1. Server Identity Validation
- **Issue Fixed**: Prevents accidental deployment to wrong servers
- **Implementation**: Pre-flight check ensures only orchestration server runs deployment

### 2. Secure Logging
- **Issue Fixed**: Multi-line log entries properly formatted
- **Implementation**: Uses `blockinfile` instead of `lineinfile` for complex log entries

### 3. No Insecure Downloads
- **Issue Fixed**: Eliminates curl-pipe-to-shell installations
- **Implementation**: Validates existing Ollama installation, fails safely if missing

## Usage

### Basic Deployment
```yaml
- hosts: hx-orchestration-server
  roles:
    - deploy_embedding_models
```

### Custom Configuration
```yaml
- hosts: hx-orchestration-server
  roles:
    - role: deploy_embedding_models
      vars:
        retry_attempts: 5
        test_endpoints: false
        deployment_log_file: "/var/log/custom-embedding-deploy.log"
```

## Error Handling

The role includes comprehensive error handling:

1. **Pre-flight Checks**:
   - Server identity validation
   - Ollama installation verification
   - CUDA availability confirmation
   - Disk space assessment

2. **Deployment Resilience**:
   - Retry logic for network operations
   - Service readiness verification
   - Comprehensive status logging

3. **Post-deployment Validation**:
   - API endpoint testing
   - Model functionality verification
   - Remote accessibility confirmation

## Integration

This role integrates with the CX R&D Infrastructure:

- **API Gateway**: Embedding endpoints accessible via gateway
- **Vector Database**: Models support Qdrant vector operations
- **Web Interface**: Models available for embedding operations
- **Monitoring**: Deployment logged for audit trail

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
