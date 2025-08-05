# Host Name Consistency Fix

## Issue
The embedding deployment playbook was targeting `hosts: hx-orc-server` but the Phase 5 inventory uses `cx-orchestration` as the host name, causing deployment failures.

## Solution
Updated playbooks to use parameterized host targeting with inventory-consistent defaults:

### Before (Hard-coded, Mismatched)
```yaml
# deploy-embeddings.yml
hosts: hx-orc-server  # ❌ Not in inventory

# deploy-orchestration-server.yml  
hosts: hx-orc-server  # ❌ Not in inventory
```

### After (Parameterized, Flexible)
```yaml
# deploy-embeddings.yml
hosts: "{{ embedding_host | default('cx-orchestration') }}"

# deploy-orchestration-server.yml
hosts: "{{ orchestration_host | default('cx-orchestration') }}"
```

## Benefits
1. **Inventory Consistency**: Matches actual host names in phase5-inventory.yml
2. **Flexibility**: Can override host targeting via variables
3. **Environment Support**: Works across different inventory configurations
4. **Future-Proof**: Easy to update for different naming conventions

## Inventory Verification
The `cx-orchestration` host exists in the inventory with:
- **IP**: 192.168.10.31
- **Role**: orchestration_embedding  
- **Group Membership**: llm_servers
- **Models**: nomic-embed-text:v1.5

## Variable Defaults Updated
- `embedding_host`: "cx-orchestration" (in role defaults)
- `orchestration_host`: "cx-orchestration" (in playbook vars)

## Usage Examples
```bash
# Use default inventory host
ansible-playbook deploy-embeddings.yml -i phase5-inventory.yml

# Override for different environment
ansible-playbook deploy-embeddings.yml -i dev-inventory.yml -e embedding_host=dev-orchestration

# Override for specific host
ansible-playbook deploy-embeddings.yml -e embedding_host=hx-orc-server
```

This fix ensures deployments work correctly with the committed inventory structure while maintaining flexibility for different environments.
