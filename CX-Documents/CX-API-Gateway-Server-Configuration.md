# CX-API Gateway Server Configuration Summary

**Designation:** CX-API Gateway  
**Hostname:** hx-api-gateway-server  
**IP Address:** 192.168.10.39  
**Date Captured:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

This server will serve as the Citadel-X API Gateway, acting as the routing and load-balancing layer between external services (e.g., OpenWebUI, tools, agents) and internal LLM infrastructure (e.g., Ollama runtimes, embedding services). As of this capture, the server is fully provisioned but no software stack has yet been deployed. This document records the current baseline state and confirms readiness for the API gateway stack installation.

## Table of Contents

1. [Purpose](#purpose)
2. [Hardware & OS Configuration](#2-hardware--os-configuration)
3. [Storage Configuration](#3-storage-configuration)
4. [Network Configuration](#4-network-configuration)
5. [User Context & Permissions](#5-user-context--permissions)
6. [Installed Runtimes](#6-installed-runtimes)
7. [Application Status](#7-application-status)
8. [Recommendations for First Deployment](#8-recommendations-for-first-deployment)

---

## 2. Hardware & OS Configuration

| Component | Detail |
|-----------|--------|
| CPU | Intel Core i7-10510U (8 vCPUs) |
| RAM | 7.4 GiB physical memory |
| Swap | 4 GiB (/swap.img) |
| OS | Ubuntu 24.04.2 LTS (noble) |
| Kernel | 6.14.0-24-generic |
| Time Sync | NTP active, UTC time zone |

---

## 3. Storage Configuration

| Device | Mount Point | Filesystem | Size | Usage | Notes |
|--------|-------------|------------|------|-------|-------|
| `/dev/nvme0n1p2` | `/` | ext4 | 1.8 TB | 6.6 GB used | Primary root volume |
| `/dev/nvme0n1p1` | `/boot/efi` | vfat | 1.1 GB | Minimal usage | EFI system partition |

No additional disks or mounts are present. All devices use UUID-based mounting per `/etc/fstab`.

---

## 4. Network Configuration

### Interface Configuration

| Interface | Address | Scope |
|-----------|---------|-------|
| enp4s0 | 192.168.10.39/24 | Global |
| lo | 127.0.0.1/8 | Local |
| ::1, others | IPv6 (loopback/link) | Local |

### Open Ports (Currently)

| Port | Service | Protocol | Binding |
|------|---------|----------|---------|
| 22 | SSH | TCP | 0.0.0.0 / [::] |

**Note:** No application ports are exposed (e.g., 8000/8080 for FastAPI or Uvicorn). Firewall rules and iptables require root access to verify further.

---

## 5. User Context & Permissions

| User | Groups |
|------|--------|
| agent0 | adm, sudo, cdrom, dip, plugdev, lxd |

This user has full sudo privileges and system-level control. All application deployments will occur within this context unless a system user is created.

---

## 6. Installed Runtimes

| Runtime | Version | Status |
|---------|---------|--------|
| Python | 3.12.3 | ✅ Installed |
| Node.js | N/A | ❌ Not installed |
| npm | N/A | ❌ Not installed |

Node/npm must be installed prior to building any frontend or handling JavaScript-based gateway logic (e.g., websockets, Clerk integrations, etc.).

---

## 7. Application Status

| Application | Status | Notes |
|-------------|--------|-------|
| FastAPI Gateway | ❌ Not installed | No application stack or ports active |
| Ollama Client | ❌ Not installed | Ollama is expected downstream (API proxy) |
| NGINX / Proxy | ❌ Not installed | No reverse proxy configured |

No applications are running or configured yet. The server is clean and ready for setup.

---

## 8. Recommendations for First Deployment

| Task | Priority |
|------|----------|
| Install Node.js + npm | High |
| Initialize Python virtualenv for FastAPI | High |
| Create api-gateway.service (systemd) | Medium |
| Set up CORS + Forwarded IP headers | Medium |
| Configure NGINX reverse proxy with TLS | Medium |
| Pull Ollama model registry config (if applicable) | Optional |
| Lock unused ports via ufw or iptables | High |

### Implementation Roadmap

#### Phase 1: Runtime Setup (High Priority)

1. **Install Node.js and npm**

   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **Setup Python Virtual Environment**

   ```bash
   python3 -m venv /opt/citadel-api-gateway
   source /opt/citadel-api-gateway/bin/activate
   pip install fastapi uvicorn[standard]
   ```

#### Phase 2: Service Configuration (Medium Priority)

1. **Create Systemd Service**
   - Location: `/etc/systemd/system/api-gateway.service`
   - User: Create dedicated service user
   - Auto-restart on failure

2. **CORS and Security Headers**
   - Configure allowed origins
   - Implement rate limiting
   - Setup forwarded IP handling

#### Phase 3: Infrastructure (Medium Priority)

1. **NGINX Reverse Proxy**
   - TLS termination
   - Load balancing capabilities
   - WebSocket support for real-time features

2. **Firewall Configuration**
   - Lock down unnecessary ports
   - Allow only required traffic
   - Document security rules

### Expected Port Configuration Post-Deployment

| Port | Service | Purpose | Security |
|------|---------|---------|----------|
| 8000 | FastAPI Gateway | Main API endpoint | Internal only |
| 80 | NGINX (HTTP) | Redirect to HTTPS | Public |
| 443 | NGINX (HTTPS) | TLS-terminated gateway | Public |
| 22 | SSH | Remote administration | Restricted IP |

### Integration Points

- **Upstream:** OpenWebUI (192.168.10.38:8080)
- **Downstream:** Ollama servers (192.168.10.28:11434, 192.168.10.29:11434)
- **Monitoring:** CX-Metric Server (192.168.10.30)
- **Orchestration:** CX-LLM Server (192.168.10.31)

---

## Next Steps

1. **Immediate:** Install Node.js and npm runtimes
2. **Short-term:** Deploy FastAPI gateway application
3. **Medium-term:** Configure NGINX reverse proxy with TLS
4. **Long-term:** Implement advanced routing and load balancing logic

**Status:** Ready for deployment - all prerequisites met, clean baseline established.
