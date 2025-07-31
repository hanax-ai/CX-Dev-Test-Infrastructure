# CX Embedding Models Deployment

This directory contains automation scripts for deploying embedding models to the CX Infrastructure orchestration server.

## Overview

Automated deployment of three embedding models to **hx-orc-server (192.168.10.31)**:

- **mxbai-embed-large** (334M parameters) - High-quality text representations
- **nomic-embed-text** (137M parameters) - Efficient text embedding
- **all-minilm** (23M parameters) - Lightweight, fast inference

## Prerequisites

### Linux/macOS (Ansible)
- Ansible installed (`pip install ansible`)
- SSH access configured to server (private key at `~/.ssh/id_rsa`)
- User `agent0` with sudo privileges on target server

### Windows (PowerShell)
- PowerShell 5.1+ or PowerShell Core
- SSH client (Windows 10/11 built-in or OpenSSH)
- Network access to server 192.168.10.31

## Deployment Options

### Option 1: Ansible (Linux/macOS/WSL)

#### Quick Deployment
```bash
# Navigate to ansible directory
cd ansible/

# Run deployment
./deploy-models.sh
```

#### Advanced Options
```bash
# Dry run (no changes)
./deploy-models.sh --dry-run

# Verify existing deployment
./deploy-models.sh --verify-only

# Manual ansible execution
ansible-playbook -i inventory/hosts.yml playbooks/deploy-embedding-models.yml
```

### Option 2: PowerShell (Windows)

#### Quick Deployment
```powershell
# Navigate to ansible directory
cd ansible\

# Run deployment
.\Deploy-EmbeddingModels.ps1
```

#### Advanced Options
```powershell
# Dry run mode
.\Deploy-EmbeddingModels.ps1 -Action dry-run

# Verify existing deployment
.\Deploy-EmbeddingModels.ps1 -Action verify

# Verbose output
.\Deploy-EmbeddingModels.ps1 -Verbose

# Custom server IP
.\Deploy-EmbeddingModels.ps1 -ServerIP "192.168.10.31" -Username "agent0"
```

## What Gets Deployed

### Models Installed
1. **mxbai-embed-large**
   - Size: 334M parameters
   - Purpose: High-quality embeddings for complex text analysis
   - Use case: Production embedding service

2. **nomic-embed-text**
   - Size: 137M parameters
   - Purpose: Balanced performance and efficiency
   - Use case: General-purpose text embedding

3. **all-minilm**
   - Size: 23M parameters
   - Purpose: Fast, lightweight embeddings
   - Use case: Real-time applications, high-throughput scenarios

### Configuration Applied
- Models installed to `/opt/ai_models` on orchestration server
- Ollama service configured for network access (`0.0.0.0:11434`)
- GPU acceleration enabled (CUDA 12.9)
- Network API endpoints exposed for downstream services

## Post-Deployment Verification

### API Testing
```bash
# Test mxbai-embed-large
curl -X POST "http://192.168.10.31:11434/api/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"model":"mxbai-embed-large","prompt":"test embedding"}'

# Test nomic-embed-text
curl -X POST "http://192.168.10.31:11434/api/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"model":"nomic-embed-text","prompt":"test embedding"}'

# Test all-minilm
curl -X POST "http://192.168.10.31:11434/api/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"model":"all-minilm","prompt":"test embedding"}'
```

### Service Status
```bash
# SSH to server
ssh agent0@192.168.10.31

# Check Ollama status
systemctl status ollama

# List installed models
ollama list

# Check disk usage
df -h /opt/ai_models
```

## Integration with CX Infrastructure

### API Gateway Integration
The embedding models will be accessible through the planned FastAPI gateway at `192.168.10.39`:

```python
# Example integration
import requests

response = requests.post(
    "http://192.168.10.39/api/embeddings",
    json={
        "model": "mxbai-embed-large",
        "text": "Your text to embed",
        "server": "orchestration"
    }
)
embeddings = response.json()["embeddings"]
```

### LLM Server Coordination
The orchestration server provides embedding services to both LLM servers:
- **hx-llm-server-01** (192.168.10.34) - Chat models
- **hx-llm-server-02** (192.168.10.28) - Instruct models

### Vector Database Integration
Embeddings are designed to work with the Qdrant vector database on `192.168.10.30`:

```python
# Example workflow
text = "Document to embed"
embeddings = get_embeddings(text, model="mxbai-embed-large")
qdrant_client.upsert(collection="documents", vectors=embeddings)
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key is configured: `ssh-keygen -t rsa -b 4096`
   - Test connection: `ssh agent0@192.168.10.31`
   - Check firewall settings on target server

2. **Ollama Service Not Running**
   ```bash
   sudo systemctl start ollama
   sudo systemctl enable ollama
   ```

3. **Model Download Failed**
   - Check internet connectivity on server
   - Verify disk space: `df -h /opt/ai_models`
   - Check Ollama logs: `journalctl -u ollama -f`

4. **API Not Responding**
   - Verify Ollama is bound to network: `netstat -tlnp | grep 11434`
   - Check firewall: `sudo ufw status`
   - Test locally first: `curl http://localhost:11434/api/embeddings`

### Log Files
- **Ansible**: `./logs/ansible.log` and `./logs/deployment_*.log`
- **PowerShell**: `./logs/deployment_*.log`
- **Server**: `/var/log/cx-embedding-deployment.log`

## File Structure

```
ansible/
├── ansible.cfg                     # Ansible configuration
├── inventory/
│   └── hosts.yml                   # Server inventory
├── playbooks/
│   └── deploy-embedding-models.yml # Ansible playbook
├── logs/                           # Deployment logs
├── deploy-models.sh                # Linux/macOS deployment script
├── Deploy-EmbeddingModels.ps1      # Windows PowerShell script
└── README.md                       # This file
```

## Next Steps

After successful deployment:

1. **Update Documentation**: Add models to infrastructure documentation
2. **Configure API Gateway**: Set up routing to embedding endpoints
3. **Integrate with Applications**: Update LLM servers to use embedding service
4. **Monitor Performance**: Set up Grafana dashboards for embedding metrics
5. **Backup Configuration**: Include models in backup strategy

## Support

For issues with the deployment automation:
- Check logs in the `logs/` directory
- Verify server configuration in the main documentation
- Ensure network connectivity and permissions are correct
