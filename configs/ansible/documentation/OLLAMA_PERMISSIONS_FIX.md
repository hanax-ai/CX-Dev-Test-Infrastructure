# Ollama File Permissions Fix - Implementation Documentation

## Overview
This document describes the implementation of Ollama file permissions fixes across all AI Processing Tier servers to resolve deployment issues identified in the engineering review.

## Problem Statement
The `/opt/ai_models` directory was being created with `agent0:agent0` ownership, but the Ollama service runs under the `ollama:ollama` user account, causing permission denied errors during model operations.

## Solution Implementation

### 1. Updated Deployment Playbooks
The following playbooks have been updated with the permissions fix task:

- `deploy-llm-server-01.yml` - Task 6.1 added
- `deploy-llm-server-02.yml` - Task 6.1 added  
- `deploy-orchestration-server.yml` - Task 6.1 added

### 2. Permissions Fix Task
```yaml
- name: 6.1. Ensure /opt/ai_models has correct permissions for Ollama
  file:
    path: /opt/ai_models
    state: directory
    owner: ollama
    group: ollama
    recurse: yes
  when: "'ai_processing_tier' in group_names"
```

### 3. Standalone Fix Playbook
Created `fix-ollama-permissions.yml` for applying permissions fixes to existing deployments:

```bash
# Run on all AI processing servers
ansible-playbook fix-ollama-permissions.yml

# Run on specific server
ansible-playbook fix-ollama-permissions.yml --limit hx-llm-server-01
```

### 4. Test Validation
Created `test-ollama-permissions.yml` to validate the permissions fix logic on test servers.

## Implementation Details

### Task Placement
The permissions fix task (6.1) is strategically placed:
- **After**: Directory creation (Task 6)
- **Before**: Ollama service start/restart (Task 7)

This ensures:
1. Directory exists before fixing permissions
2. Permissions are correct before Ollama starts
3. No service interruption during deployment

### Conditional Execution
The task includes `when: "'ai_processing_tier' in group_names"` to ensure it only runs on appropriate servers.

### Recursive Application
The `recurse: yes` parameter ensures all existing model files and subdirectories get correct ownership.

## Validation Commands

### Check Permissions
```bash
# On target servers
ls -la /opt/ai_models/

# Expected output: ollama:ollama ownership
```

### Test Ollama Functionality
```bash
# Test API access
curl http://localhost:11434/api/tags

# Test model operations
ollama list
```

### Ansible Validation
```bash
# Check playbook syntax
ansible-playbook --syntax-check deploy-llm-server-01.yml

# Run in check mode
ansible-playbook fix-ollama-permissions.yml --check
```

## Files Modified
- `/configs/ansible/deploy-llm-server-01.yml`
- `/configs/ansible/deploy-llm-server-02.yml`
- `/configs/ansible/deploy-orchestration-server.yml`

## Files Created
- `/configs/ansible/fix-ollama-permissions.yml`
- `/configs/ansible/test-ollama-permissions.yml`

## Deployment Impact
- **Risk Level**: Low - Permissions fix is non-destructive
- **Downtime**: Minimal - Only during Ollama service restart
- **Rollback**: Automatic via original task if needed

## Next Steps
1. Test on hx-test-server (if Ollama installed)
2. Deploy to AI processing tier servers
3. Validate model operations post-deployment
4. Monitor for permission-related errors
