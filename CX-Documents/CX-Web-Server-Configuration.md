# CX-Web Server Configuration Summary

**Designation:** CX-Web  
**Hostname:** hx-web-server  
**IP Address:** 192.168.10.38  
**Date Captured:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

The CX-Web Server hosts OpenWebUI, the interactive user-facing interface to Citadel-X's LLM API layer. It connects to Ollama model runtimes and optionally routes via a FastAPI gateway. This document defines the complete system configuration, service behavior, environment setup, and runtime bindings.

## Table of Contents

1. [Purpose](#purpose)
2. [Hardware & OS Profile](#2-hardware--os-profile)
3. [Disk & Filesystem Layout](#3-disk--filesystem-layout)
4. [Software Stack](#4-software-stack)
5. [OpenWebUI Runtime Configuration](#5-openwebui-runtime-configuration)
6. [Environment Configuration (.env)](#6-environment-configuration-env)
7. [Network & Security Profile](#7-network--security-profile)
8. [Current Issues & Observations](#8-current-issues--observations)
9. [Recommendations](#9-recommendations)

---

## 2. Hardware & OS Profile

| Component | Detail |
|-----------|--------|
| CPU | Intel Core i7-7700HQ (8 vCPUs) |
| RAM | 15 GiB physical memory |
| Swap | 4 GiB file-based swap (/swap.img) |
| OS | Ubuntu 24.04.2 LTS (noble) |
| Kernel | 6.14.0-24-generic |
| Time Sync | NTP active and system clock synced |
| Timezone | UTC (Etc/UTC) |

---

## 3. Disk & Filesystem Layout

| Mount Point | Device | Type | Size | Usage | Notes |
|-------------|--------|------|------|-------|-------|
| `/` | `/dev/sda2` | ext4 | 916 GB | 4% | Root OS and application stack |
| `/mnt/external` | `/dev/sdb1` | ext4 | 7.3 GB | 1% | External mount (optional use) |

All mounts are managed by `/etc/fstab` using UUIDs. No LVM or RAID is configured.

---

## 4. Software Stack

| Component | Version | Installed | Notes |
|-----------|---------|-----------|-------|
| Python | 3.12.3 | ✅ | Used by Uvicorn to run OpenWebUI |
| Node.js | v20.19.4 | ✅ | Required for UI asset build |
| npm | 10.8.2 | ✅ | Supports WebUI build and assets |
| Docker | Not Active | ❌ | Docker socket inaccessible |

**Note:** OpenWebUI is installed from source, not Docker. Confirmed by absence of Docker containers and presence of Uvicorn service.

---

## 5. OpenWebUI Runtime Configuration

| Property | Value |
|----------|-------|
| Launch Method | Manual execution via uvicorn |
| Command | `/usr/local/bin/python3 -m uvicorn open_webui.main:app --host 0.0.0.0 --port 8080` |
| Listening Port | 8080 (HTTP) |
| Run User | root (service-level, from shell) |
| Process Ownership | Verified via ps aux |
| Working Directory | `/home/agent0/open-webui` |
| Systemd Service | Not configured |
| Logs | No errors in syslog; not daemonized |

---

## 6. Environment Configuration (.env)

`.env` is located at:

```text
/home/agent0/open-webui/.env
```

To inspect runtime integration:

```bash
cat /home/agent0/open-webui/.env | grep -iE 'OLLAMA|OPENAI|CORS|SCARF|TELEMETRY'
```

### Expected key variables

- `OLLAMA_BASE_URL=http://192.168.10.28:11434`
- `CORS_ALLOW_ORIGIN=*`
- `SCARF_NO_ANALYTICS=true`
- `ANONYMIZED_TELEMETRY=false`

---

## 7. Network & Security Profile

| Port | Service | Protocol | Bound IP | Notes |
|------|---------|----------|----------|-------|
| 80 | HTTP | TCP | 0.0.0.0, [::] | Default HTTP port open |
| 3000 | Unidentified (possibly test app) | TCP | 0.0.0.0, [::] | Exposed; needs audit |
| 8080 | OpenWebUI | TCP | 0.0.0.0 | Failed to connect — likely down |
| 22 | SSH | TCP | 0.0.0.0, [::] | Remote access |

**Firewall Status:** ufw inactive or insufficient privileges to access  
**Iptables Status:** Restricted (requires root to view)

---

## 8. Current Issues & Observations

### 🔸 Port 8080 not responding

`curl -I http://localhost:8080` failed

**Suggestion:** Verify if Uvicorn crashed or is bound to a different user session

### 🔸 No systemd service for OpenWebUI

**Suggestion:** Consider creating `/etc/systemd/system/openwebui.service` for reliable startup

### 🔸 Running as root manually is a security concern

**Suggestion:** Prefer a system user like agent0 or a dedicated service account

### 🔸 No HTTPS

HTTP-only access over port 8080 is currently exposed; reverse proxy + TLS termination advised

---

## 9. Recommendations

| Action Item | Priority | Rationale |
|-------------|----------|-----------|
| Configure openwebui.service with systemd | High | Ensures autostart and crash recovery |
| Enable TLS via reverse proxy (e.g., NGINX) | High | Protects user interaction and API tokens |
| Restrict port 8080 to internal subnet or via firewall | High | Prevents accidental external exposure |
| Review and document .env config completely | Medium | Confirms correct Ollama/API routing |
| Migrate to non-root user for running services | Medium | Aligns with Citadel-X service standards |

### Implementation Priority Matrix

#### High Priority (Immediate Action Required)

1. **Service Configuration:** Create systemd service for reliable startup
2. **Security Hardening:** Implement TLS termination and access controls
3. **Network Security:** Configure proper firewall rules

#### Medium Priority (Near-term Improvements)

1. **Configuration Audit:** Complete documentation of environment variables
2. **User Security:** Migrate from root to service user
3. **Monitoring Integration:** Add to CX-Metric server monitoring

---

## Next Steps

1. **Immediate:** Investigate port 8080 connectivity issues
2. **Short-term:** Implement systemd service configuration
3. **Medium-term:** Deploy reverse proxy with TLS
4. **Long-term:** Integrate with centralized authentication system
