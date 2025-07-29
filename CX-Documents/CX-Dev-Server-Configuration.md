# CX-Dev Server Configuration Summary

**Designation:** CX-Dev  
**Hostname:** hx-dev-server  
**IP Address:** 192.168.10.33  
**Date Captured:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

The CX-Dev Server provides an isolated, resource-rich environment for local AI development, model experimentation, and prototype testing within the Citadel-X architecture. No production applications are active as of this baseline, but Python is installed and the server is ready for onboarding development frameworks.

## Table of Contents

1. [Purpose](#purpose)
2. [Hardware & OS Configuration](#2-hardware--os-configuration)
3. [Storage Configuration](#3-storage-configuration)
4. [Network Configuration](#4-network-configuration)
5. [User & Privilege Context](#5-user--privilege-context)
6. [Installed Runtimes](#6-installed-runtimes)
7. [Development Environment Setup](#7-development-environment-setup)
8. [Recommended Development Stack](#8-recommended-development-stack)
9. [Next Steps](#9-next-steps)

---

## 2. Hardware & OS Configuration

| Component | Detail |
|-----------|--------|
| CPU | Intel Xeon W-2123 (8 vCPUs @ 3.60 GHz) |
| RAM | 125 GiB |
| Swap | 8 GiB (/swap.img) |
| OS | Ubuntu 24.04.2 LTS (noble) |
| Kernel | 6.11.0-29-generic |
| Time Sync | NTP active, UTC time zone |

**Performance Note:** This server has exceptional memory capacity (125 GiB) making it ideal for large model development, dataset processing, and memory-intensive AI workloads.

---

## 3. Storage Configuration

| Device | Mount Point | Filesystem | Size | Usage | Notes |
|--------|-------------|------------|------|-------|-------|
| `/dev/sda2` | `/` | ext4 | 879 GB | 12 GB | Main OS and application space |
| `/dev/sda1` | `/boot/efi` | vfat | 1.1 GB | 6.2 MB | EFI partition |
| `/dev/sdb1` | Not mounted | ntfs | 3.6 TB | — | Large data disk, candidate for /data |

**Note:** Secondary disk (`/dev/sdb1`) is unmounted and formatted NTFS — likely migrated from Windows or portable storage. Mount and reformat may be needed for native use (ext4 or xfs recommended).

### Storage Recommendations

1. **Reformat secondary disk** to ext4 or xfs for optimal Linux performance
2. **Mount as `/data`** for datasets, models, and development artifacts
3. **Consider LVM setup** for flexible storage management

---

## 4. Network Configuration

### Interface Configuration

| Interface | Address | Scope |
|-----------|---------|-------|
| eno1 | 192.168.10.33/24 | Global |
| lo | 127.0.0.1/8 | Local |

### Open Ports (Currently)

| Port | Service | Protocol | Binding |
|------|---------|----------|---------|
| 22 | SSH | TCP | 0.0.0.0 / [::] |

No applications or services are currently listening on high ports (8000+, etc.). Firewall details (ufw/iptables) require root access to confirm.

---

## 5. User & Privilege Context

| User | Groups |
|------|--------|
| agent0 | adm, sudo, cdrom, dip, plugdev, lxd |

- **Full sudo privileges confirmed**
- All development work will occur under this user context unless segmented

---

## 6. Installed Runtimes

| Runtime | Version | Status |
|---------|---------|--------|
| Python | 3.12.3 | ✅ Installed |
| Node.js | Not present | ❌ |
| npm | Not present | ❌ |

---

## 7. Development Environment Setup

### Current Status

- **Clean baseline** - No development frameworks installed
- **Python ready** - Core runtime available for AI/ML development
- **Storage pending** - Large data disk requires configuration
- **Network isolated** - No exposed application ports

### Recommended Initial Setup

#### Phase 1: Core Development Tools

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential development tools
sudo apt install -y git vim curl wget build-essential

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker for containerized development
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker agent0
```

#### Phase 2: Python Development Environment

```bash
# Install Python development packages
sudo apt install -y python3-pip python3-venv python3-dev

# Install AI/ML frameworks
pip3 install --user jupyter notebook pandas numpy matplotlib scikit-learn
pip3 install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip3 install --user transformers datasets accelerate
```

#### Phase 3: Storage Configuration

```bash
# Format and mount secondary disk
sudo mkfs.ext4 /dev/sdb1
sudo mkdir /data
sudo mount /dev/sdb1 /data
sudo chown agent0:agent0 /data

# Add to fstab for persistent mounting
echo "/dev/sdb1 /data ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

---

## 8. Recommended Development Stack

### AI/ML Development

| Tool | Purpose | Priority |
|------|---------|----------|
| Jupyter Lab | Interactive development | High |
| PyTorch | Deep learning framework | High |
| Transformers | LLM development | High |
| Ollama | Local model serving | High |
| MLflow | Experiment tracking | Medium |
| Weight & Biases | Model monitoring | Medium |

### General Development

| Tool | Purpose | Priority |
|------|---------|----------|
| VS Code Server | Remote development | High |
| Git | Version control | High |
| Docker | Containerization | High |
| NGINX | Local web serving | Medium |
| PostgreSQL | Database development | Medium |

### Expected Port Configuration Post-Setup

| Port | Service | Purpose | Security |
|------|---------|---------|----------|
| 8888 | Jupyter Lab | Interactive development | Internal only |
| 8000 | Development server | API testing | Internal only |
| 11434 | Ollama (if installed) | Local model serving | Internal only |
| 5000 | MLflow | Experiment tracking | Internal only |
| 8080 | VS Code Server | Remote development | VPN/SSH tunnel |

---

## 9. Next Steps

### Immediate Actions (High Priority)

1. **Configure secondary storage**
   - Reformat `/dev/sdb1` to ext4
   - Mount as `/data` with proper permissions
   - Update `/etc/fstab` for persistence

2. **Install core development tools**
   - Node.js and npm for full-stack development
   - Docker for containerized environments
   - Git for version control

### Short-term Setup (Medium Priority)

1. **AI/ML Development Environment**
   - Install Jupyter Lab and core ML libraries
   - Setup PyTorch and Transformers
   - Configure Ollama for local model serving

2. **Development Infrastructure**
   - Install VS Code Server for remote development
   - Setup database (PostgreSQL/SQLite)
   - Configure NGINX for local web serving

### Long-term Integration (Lower Priority)

1. **Citadel-X Integration**
   - Connect to CX-Metric server for monitoring
   - Setup shared storage with other servers
   - Implement backup and disaster recovery

2. **Advanced Development Features**
   - GPU support (if hardware upgraded)
   - Distributed computing setup
   - Container orchestration

### Development Workflow Recommendations

#### Project Structure

```text
/data/
├── projects/           # Active development projects
├── datasets/          # Training and test datasets  
├── models/            # Trained models and checkpoints
├── experiments/       # ML experiment artifacts
└── shared/            # Shared resources and utilities
```

#### Integration Points

- **Model Storage:** `/data/models` for trained model artifacts
- **Dataset Storage:** `/data/datasets` for training data
- **Experiment Tracking:** MLflow server on port 5000
- **Model Serving:** Ollama integration with CX infrastructure
- **Monitoring:** Integration with CX-Metric server (192.168.10.30)

---

## Development Server Specifications

**Optimal Use Cases:**

- Large language model fine-tuning and experimentation
- Dataset preprocessing and analysis
- Prototype API development and testing
- Multi-model inference testing
- Memory-intensive ML workloads

**Resource Allocation:**

- **Memory:** 125 GiB allows for loading multiple large models simultaneously
- **Storage:** 3.6 TB secondary disk ideal for datasets and model storage
- **CPU:** 8-core Xeon suitable for CPU-intensive training tasks
- **Network:** Isolated development with access to production infrastructure

**Status:** Ready for development stack deployment - excellent hardware foundation established.
