# CX-DevOps Server Configuration Summary

**Designation:** CX-DevOps  
**Hostname:** hx-dev-ops-server  
**IP Address:** 192.168.10.36  
**Date Captured:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

Reserved for DevOps tooling, infrastructure automation, configuration management, and monitoring integration within the Citadel-X platform. This system has not yet been provisioned with applications or workloads.

## Table of Contents

1. [Purpose](#purpose)
2. [Operating System & Kernel](#2-operating-system--kernel)
3. [CPU & Memory](#3-cpu--memory)
4. [Storage Layout](#4-storage-layout)
5. [Network Configuration](#5-network-configuration)
6. [Runtime Environment](#6-runtime-environment)
7. [Partition Mount Points](#7-partition-mount-points)
8. [DevOps Infrastructure Recommendations](#8-devops-infrastructure-recommendations)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Next Steps](#10-next-steps)

---

## 2. Operating System & Kernel

| Component | Detail |
|-----------|--------|
| OS | Ubuntu 24.04.2 LTS (noble) |
| Kernel | 6.11.0-29-generic (SMP PREEMPT_DYNAMIC) |
| Time Zone | UTC (NTP synchronized: ✔️) |

---

## 3. CPU & Memory

| Component | Detail |
|-----------|--------|
| CPU Model | Intel® Xeon® W-2125 @ 4.00GHz |
| Cores / Threads | 4 cores / 8 threads |
| Max Frequency | 4.5 GHz |
| RAM | 62 GiB DDR4 |
| Swap | 8 GiB (/swap.img, active) |

**Performance Note:** High-frequency Xeon processor with substantial memory ideal for CI/CD workloads, container orchestration, and infrastructure automation tasks.

---

## 4. Storage Layout

### Primary Storage (Boot + Root)

| Device | Size | Type | Mount Point | Filesystem |
|--------|------|------|-------------|------------|
| `/dev/sda` | 1.8 TB total | Primary disk | — | — |
| `/dev/sda1` | 1 GB | EFI | `/boot/efi` | vfat |
| `/dev/sda2` | 2 GB | Boot | `/boot` | ext4 |
| `/dev/sda3` | 1.8 TB | LVM2 Physical Volume | — | — |
| `ubuntu--vg-ubuntu--lv` | 100 GB | LVM Logical Volume | `/` | ext4 |

### Additional Unmounted Drives

| Device | Size | Filesystem | Status | Potential Use |
|--------|------|------------|--------|---------------|
| `/dev/sdb` | 7.3 TB | NTFS (Partition: `/dev/sdb2`) | Unmounted | Build cache / CI artifacts |
| `/dev/sdc` | 7.3 TB | NTFS (Partition: `/dev/sdc1`) | Unmounted | Backup storage / Archives |
| `/dev/sdd` | 7.3 TB | NTFS (Partition: `/dev/sdd1`) | Unmounted | Container registry / Images |

**Note:** All three secondary disks are currently unmounted and unformatted in `/etc/fstab`. Total additional storage capacity: **21.9 TB**.

### Storage Recommendations

1. **Reformat secondary disks** to ext4 for optimal Linux performance
2. **LVM integration** - Add to existing volume group for flexible management
3. **Dedicated mount points:**
   - `/dev/sdb` → `/devops/cache` (Build artifacts, CI/CD cache)
   - `/dev/sdc` → `/devops/backup` (Infrastructure backups, configuration archives)
   - `/dev/sdd` → `/devops/registry` (Container images, package registry)

---

## 5. Network Configuration

### Interface Configuration

| Component | Detail |
|-----------|--------|
| Primary Interface | eno1 |
| IP Address | 192.168.10.36/24 |
| Firewall | No UFW rules defined (ufw status: inactive or not configured) |

### Open Ports

| Port | Service | Protocol | Notes |
|------|---------|----------|-------|
| 22 | SSH | TCP | Remote administration |
| 53 | Local DNS stub resolver | TCP/UDP | systemd-resolved |

---

## 6. Runtime Environment

| Component | Version/Status |
|-----------|----------------|
| Python | 3.12.3 |
| Node.js / npm | Not installed |
| System Groups | sudo, adm, cdrom, dip, plugdev, lxd |
| User | agent0 |

---

## 7. Partition Mount Points

From `/etc/fstab`:

```fstab
/dev/mapper/ubuntu--vg-ubuntu--lv /         ext4 defaults 0 1
/dev/sda2                        /boot     ext4 defaults 0 1
/dev/sda1                        /boot/efi vfat defaults 0 1
/swap.img                        none      swap sw       0 0
```

---

## 8. DevOps Infrastructure Recommendations

### Core DevOps Stack

#### Phase 1: Essential DevOps Tools

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y git curl wget unzip software-properties-common

# Install Docker and Docker Compose
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker agent0

# Install Node.js for modern tooling
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install additional development tools
sudo apt install -y build-essential python3-pip python3-venv
```

#### Phase 2: CI/CD Infrastructure

```bash
# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install -y jenkins

# Install GitLab Runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt install -y gitlab-runner

# Install Ansible for configuration management
sudo apt install -y ansible

# Install Terraform for infrastructure as code
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
```

#### Phase 3: Storage Configuration for DevOps

```bash
# Format and setup DevOps storage
sudo mkfs.ext4 /dev/sdb2
sudo mkfs.ext4 /dev/sdc1
sudo mkfs.ext4 /dev/sdd1

# Create mount points
sudo mkdir -p /devops/{cache,backup,registry}

# Mount drives
sudo mount /dev/sdb2 /devops/cache
sudo mount /dev/sdc1 /devops/backup
sudo mount /dev/sdd1 /devops/registry

# Set permissions
sudo chown -R agent0:agent0 /devops/

# Add to fstab for persistence
echo "/dev/sdb2 /devops/cache ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "/dev/sdc1 /devops/backup ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "/dev/sdd1 /devops/registry ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

### DevOps Tools Portfolio

#### CI/CD & Automation

| Tool | Purpose | Port | Installation Priority |
|------|---------|------|----------------------|
| Jenkins | CI/CD automation | 8080 | High |
| GitLab Runner | GitLab CI integration | — | High |
| Ansible | Configuration management | — | High |
| Terraform | Infrastructure as Code | — | High |
| Drone CI | Lightweight CI/CD | 8081 | Medium |

#### Container & Orchestration

| Tool | Purpose | Port | Installation Priority |
|------|---------|------|----------------------|
| Docker | Containerization | — | High |
| Docker Registry | Private image registry | 5000 | High |
| Portainer | Docker management UI | 9000 | Medium |
| Watchtower | Container auto-updates | — | Medium |

#### Monitoring & Observability

| Tool | Purpose | Port | Installation Priority |
|------|---------|------|----------------------|
| Prometheus | Metrics collection | 9090 | High |
| Grafana | Visualization dashboard | 3000 | High |
| AlertManager | Alert management | 9093 | High |
| Node Exporter | System metrics | 9100 | High |

#### Security & Compliance

| Tool | Purpose | Port | Installation Priority |
|------|---------|------|----------------------|
| Vault | Secret management | 8200 | High |
| SOPS | Secret encryption | — | Medium |
| Trivy | Container scanning | — | Medium |
| OWASP ZAP | Security testing | 8082 | Medium |

---

## 9. Implementation Roadmap

### Phase 1: Foundation Setup (Week 1)

1. **Storage Configuration**
   - Format and mount 21.9 TB secondary storage
   - Configure LVM for flexible management
   - Setup DevOps directory structure

2. **Core Infrastructure**
   - Install Docker and container runtime
   - Setup Node.js and Python environments
   - Configure Git and SSH keys

### Phase 2: CI/CD Pipeline (Week 2-3)

1. **Jenkins Setup**
   - Install and configure Jenkins master
   - Setup build agents and executors
   - Configure integration with Git repositories

2. **GitLab Integration**
   - Install GitLab Runner
   - Configure CI/CD pipelines
   - Setup automated testing workflows

### Phase 3: Infrastructure Automation (Week 3-4)

1. **Configuration Management**
   - Deploy Ansible for server configuration
   - Create infrastructure playbooks
   - Setup automated deployment scripts

2. **Infrastructure as Code**
   - Install and configure Terraform
   - Create infrastructure templates
   - Setup state management and versioning

### Phase 4: Monitoring & Security (Week 4-5)

1. **Monitoring Stack**
   - Deploy Prometheus for metrics
   - Setup Grafana dashboards
   - Configure alerting and notifications

2. **Security Infrastructure**
   - Install HashiCorp Vault
   - Setup secret management
   - Configure security scanning tools

### Expected Port Configuration Post-Deployment

| Port | Service | Purpose | Security |
|------|---------|---------|----------|
| 8080 | Jenkins | CI/CD interface | Internal + VPN |
| 3000 | Grafana | Monitoring dashboard | Internal only |
| 9090 | Prometheus | Metrics collection | Internal only |
| 5000 | Docker Registry | Private image registry | Internal only |
| 8200 | Vault | Secret management | Internal + TLS |
| 9000 | Portainer | Container management | Internal only |
| 22 | SSH | Remote administration | Key-based auth |

---

## 10. Next Steps

### Immediate Actions (High Priority)

1. **Configure Secondary Storage**
   - Format 21.9 TB of additional storage
   - Setup mount points for DevOps workflows
   - Configure LVM for flexible management

2. **Install Core DevOps Stack**
   - Docker and container runtime
   - Node.js and modern tooling
   - Git and development utilities

### Short-term Setup (Medium Priority)

1. **CI/CD Infrastructure**
   - Jenkins installation and configuration
   - GitLab Runner setup
   - Automated pipeline creation

2. **Infrastructure Automation**
   - Ansible for configuration management
   - Terraform for infrastructure provisioning
   - Secret management with Vault

### Long-term Integration (Lower Priority)

1. **Citadel-X Integration**
   - Connect to existing infrastructure monitoring
   - Setup automated deployment pipelines
   - Implement infrastructure as code for all servers

2. **Advanced DevOps Features**
   - Container orchestration
   - Advanced security scanning
   - Compliance automation

### Integration with Citadel-X Infrastructure

#### DevOps Targets

| Server | IP Address | DevOps Integration |
|--------|------------|-------------------|
| CX-LLM & Orchestration | 192.168.10.31 | Automated deployment, monitoring |
| CX-Metric | 192.168.10.30 | Infrastructure monitoring integration |
| CX-Web | 192.168.10.38 | CI/CD for OpenWebUI updates |
| CX-API Gateway | 192.168.10.39 | API deployment automation |
| CX-Dev | 192.168.10.33 | Development workflow integration |
| CX-Test | 192.168.10.34 | Automated testing orchestration |

### DevOps Directory Structure

```text
/devops/
├── cache/             # CI/CD build cache and artifacts
│   ├── jenkins/       # Jenkins workspace and builds
│   ├── docker/        # Docker build cache
│   └── npm/           # Node.js package cache
├── backup/            # Infrastructure backups
│   ├── configs/       # Configuration backups
│   ├── databases/     # Database backups
│   └── secrets/       # Encrypted secret backups
└── registry/          # Container and package registries
    ├── docker/        # Private Docker registry
    ├── npm/           # Private NPM registry
    └── python/        # Private PyPI registry
```

---

## DevOps Server Specifications

**Optimal Use Cases:**

- Comprehensive CI/CD pipeline orchestration
- Infrastructure automation and configuration management
- Container registry and artifact management
- Monitoring and observability infrastructure
- Security and compliance automation

**Resource Allocation:**

- **CPU:** 4-core Xeon @ 4.0GHz ideal for build processes and automation tasks
- **Memory:** 62 GiB supports multiple concurrent CI/CD jobs and containers
- **Storage:** 21.9 TB total provides extensive capacity for build artifacts, backups, and registries
- **LVM:** Flexible storage management for growing DevOps requirements

**Status:** Ready for comprehensive DevOps infrastructure deployment - excellent foundation with massive storage capacity for enterprise-scale automation.
