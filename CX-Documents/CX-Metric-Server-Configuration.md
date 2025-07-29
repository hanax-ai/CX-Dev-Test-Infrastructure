# CX-Metric Server Configuration Summary

**Date:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

To document the configuration, role, operational scope, and service integrations of the CX-Metric Server within the Citadel-X (CX) infrastructure. This server powers observability across the Citadel AI OS, enabling metrics ingestion, dashboarding, and telemetry-based alerting. The specification also addresses operational questions relevant to deployment, integration, and future observability scaling.

## Table of Contents

1. [Server Overview](#1-server-overview)
2. [Deployment Model and Access](#2-deployment-model-and-access)
3. [Authentication and Security](#3-authentication-and-security)
4. [Metrics Coverage and Scrape Configuration](#4-metrics-coverage-and-scrape-configuration)
5. [Dashboards and Observability](#5-dashboards-and-observability)
6. [Alerts and Incident Routing](#6-alerts-and-incident-routing)
7. [Retention, Backup, and Data Policy](#7-retention-backup-and-data-policy)
8. [Ownership and Maintenance](#8-ownership-and-maintenance)
9. [Summary & Roadmap](#9-summary--roadmap)

---

## 1. Server Overview

| Attribute | Value |
|-----------|-------|
| Hostname | hx-metric-server |
| IP Address | 192.168.10.37 |
| Operating System | Ubuntu 24.04 LTS (Noble Numbat) |
| Role | CX-Metric Node |
| CPU / RAM | 8-core CPU, 32 GB RAM (min) |
| Storage | ext4-formatted disk |
| Data Paths | `/var/lib/prometheus`, `/var/lib/grafana` |

---

## 2. Deployment Model and Access

| Component | Deployment Method | Service Control | Port | Access Notes |
|-----------|-------------------|-----------------|------|--------------|
| Prometheus | Native APT package | systemd | 9090 | Public only to 192.168.10.0/24 subnet |
| Grafana | APT-managed + provisioning | systemd | 3000 | Basic auth enabled; reverse proxy planned |
| Alertmanager | Installed via APT | systemd | 9093 | Static route only; no external notifications yet |
| Node Exporter | Pre-installed on all nodes | systemd | 9100 | Scraped from all LLM and orchestration nodes |

**TLS Status:** Not currently enabled. All traffic occurs within the secured Citadel-X subnet. TLS is scheduled for Phase 2 hardening (Q3 2025).

---

## 3. Authentication and Security

| Service | Auth Type | Current Status | Planned Enhancements |
|---------|-----------|----------------|---------------------|
| Grafana | Basic Auth | Default credentials admin/admin used only in staging | OAuth2 or GitHub SSO (Q3 2025) |
| Prometheus | None | IP-whitelisted at firewall level | Reverse proxy with read-only dashboarding |
| Alertmanager | None | Localhost-only config; alerts inactive | Webhook + email integration TBD |

### Security Hardening Notes

- No public-facing interfaces exposed
- All dashboards, rule files, and provisioning scripts are backed up and tracked in internal GitOps repository
- TLS termination via NGINX with Let's Encrypt certs planned

---

## 4. Metrics Coverage and Scrape Configuration

### 🔍 Scrape Targets (Defined in prometheus.yml)

```yaml
- job_name: 'node_exporters'
  static_configs:
    - targets:
        - '192.168.10.34:9100'   # CX-LLM-01
        - '192.168.10.28:9100'   # CX-LLM-02
        - '192.168.10.36:9100'   # CX-Orchestration
        - '192.168.10.37:9100'   # CX-Metric
```

### 📈 Current Metrics Sources

| Source Node | Exporter / Endpoint | Metrics Captured |
|-------------|-------------------|------------------|
| All CX servers | Node Exporter (9100) | CPU, memory, disk I/O, load average |
| LLM Nodes (Planned) | Ollama /metrics endpoint | Model loading time, inference duration |
| Gateway (Planned) | FastAPI Prometheus hook | Request rates, latencies, queue size |

### Instrumentation Status

Node-level metrics are live. Model-layer and API-layer instrumentation is scheduled for Phase 2 rollout via Ollama hooks and FastAPI middleware.

---

## 5. Dashboards and Observability

### ✅ Live Grafana Dashboards

- **LLM Node Resource Monitor:** CPU, RAM, GPU (future), and disk usage per server
- **Server Health Heatmap:** Up/down status, restarts, file descriptor usage
- **Infrastructure Overview:** Aggregate load and uptime for CX stack

### 🛠️ Dashboard Provisioning

- Stored in `/etc/grafana/provisioning/dashboards/`
- Version-controlled via Citadel-X GitOps repo
- Automatically loaded via `.json` definitions at startup

---

## 6. Alerts and Incident Routing

### ⚠️ Current Alerting Status

| Alert | Source | Action | Status |
|-------|--------|--------|--------|
| Node Down | Prometheus | None | Configured, no routing |
| Disk Near Full | Prometheus | None | Configured |
| High Memory Use | Prometheus | None | Configured |

### Alertmanager Configuration

Present but non-functional for routing. Alerts are generated and visible in Prometheus UI but not forwarded externally.

### Next Steps

- Enable routing to email and Slack
- Define ownership policies for LLM vs infra teams
- Add Alert suppression during maintenance windows

---

## 7. Retention, Backup, and Data Policy

| Component | Retention Period | Backup Path | Notes |
|-----------|------------------|-------------|-------|
| Prometheus | 15 days (default) | `/opt/citadel/backups/` | Rotation policy active |
| Grafana | 7-day SQLite backup | Included in weekly job | PostgreSQL migration TBD |

### Long-term Storage Plan

Future migration to remote storage using Thanos or Mimir (Q4 2025) for full LLM ops audit and performance history.

---

## 8. Ownership and Maintenance

| Area | Maintainer / Owner |
|------|-------------------|
| Server OS + Packages | InfraOps (agent0) |
| Prometheus Config | LLM Infra Engineering |
| Grafana Dashboards | Citadel-X Observability |
| Alerting Policies | To be formalized |

---

## 9. Summary & Roadmap

The CX-Metric Node is fully operational as a baseline observability hub for the Citadel-X AI stack. Core system telemetry is in place, dashboards are active, and initial alert policies are configured. Instrumentation of model and API layers is partially complete, and authentication hardening and external alert routing are scheduled next.

### Key Achievements

- ✅ Complete node-level metrics collection across all CX servers
- ✅ Functional Grafana dashboards for infrastructure monitoring
- ✅ Prometheus alerting rules configured (routing pending)
- ✅ Automated backup and retention policies

### Upcoming Priorities

- 🔄 **Phase 2 (Q3 2025):** TLS implementation and authentication hardening
- 🔄 **Phase 2:** Model-layer instrumentation via Ollama metrics
- 🔄 **Phase 3 (Q4 2025):** Long-term storage migration (Thanos/Mimir)
- 🔄 **Ongoing:** Alert routing and incident management workflow
