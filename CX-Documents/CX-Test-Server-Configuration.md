# CX-Test Server Configuration Summary

**Designation:** CX-Test  
**Hostname:** hx-test-server  
**IP Address:** 192.168.10.34  
**Date Captured:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

The CX-Test Server provides an isolated environment for conducting model-level or component-level validation, staging, and regression testing of Citadel-X infrastructure modules. No applications are currently installed. The system is clean, provisioned, and ready for controlled workloads or stress test orchestration.

## Table of Contents

1. [Purpose](#purpose)
2. [Hardware & OS Configuration](#2-hardware--os-configuration)
3. [Storage Configuration](#3-storage-configuration)
4. [Network Configuration](#4-network-configuration)
5. [User & Privilege Context](#5-user--privilege-context)
6. [Installed Runtimes](#6-installed-runtimes)
7. [Storage Utilization & Mount Health](#7-storage-utilization--mount-health)
8. [Readiness Status](#8-readiness-status)
9. [Testing Framework Recommendations](#9-testing-framework-recommendations)
10. [Next Steps](#10-next-steps)

---

## 2. Hardware & OS Configuration

| Component | Detail |
|-----------|--------|
| CPU | Intel Xeon W-2133 (12 vCPUs @ 3.60 GHz) |
| RAM | 125 GiB |
| Swap | 8 GiB (/swap.img) |
| OS | Ubuntu 24.04.2 LTS (noble) |
| Kernel | 6.11.0-29-generic |
| Time Sync | NTP active, synchronized, UTC zone |

**Performance Note:** Exceptional specifications with 12-core Xeon processor and 125 GiB RAM, ideal for intensive testing workloads, parallel test execution, and stress testing scenarios.

---

## 3. Storage Configuration

| Device | Mount Point | Filesystem | Size | Usage | Notes |
|--------|-------------|------------|------|-------|-------|
| `/dev/sda2` | `/` | ext4 | 879 GB | 12 GB | Main OS and application partition |
| `/dev/sda1` | `/boot/efi` | vfat | 1.1 GB | 6.2 MB | EFI system partition |
| `/dev/sdb1` | — | ntfs | 3.6 TB | — | Unmounted NTFS (test data staging) |
| `/dev/sdc1` | — | ntfs | 3.6 TB | — | Unmounted NTFS (test archive) |

**Note:** Disks `/dev/sdb1` and `/dev/sdc1` are formatted NTFS and not mounted. Reformatting to ext4 is recommended for full write support if needed.

### Storage Recommendations

1. **Reformat secondary disks** to ext4 for optimal Linux performance
2. **Mount `/dev/sdb1` as `/test-data`** for active test datasets and artifacts
3. **Mount `/dev/sdc1` as `/test-archive`** for historical test results and backups
4. **Total available storage:** 7.2 TB for extensive test data management

---

## 4. Network Configuration

### Interface Configuration

| Interface | Address | Scope |
|-----------|---------|-------|
| eno1 | 192.168.10.34/24 | Global |
| lo | 127.0.0.1/8 | Local |

### Open Ports

| Port | Service | Protocol | Binding |
|------|---------|----------|---------|
| 22 | SSH | TCP | 0.0.0.0 / [::] |

No other application ports are active. Firewall and iptables configuration require root to fully audit.

---

## 5. User & Privilege Context

| User | Groups |
|------|--------|
| agent0 | adm, sudo, cdrom, dip, plugdev, lxd |

- **Full administrative access granted**
- All service setup or runtime installation can be conducted from this account

---

## 6. Installed Runtimes

| Runtime | Version | Status |
|---------|---------|--------|
| Python | 3.12.3 | ✅ Installed |
| Node.js | Not present | ❌ |
| npm | Not present | ❌ |

Node.js and npm are not installed. Required only if web UI testing, Clerk SDK integration, or frontend bundles are needed on this node.

---

## 7. Storage Utilization & Mount Health

| Mount Point | Size | Used | Available | Use% | Type |
|-------------|------|------|-----------|------|------|
| `/` | 879 GB | 12 GB | 822 GB | 2% | ext4 |
| `/boot/efi` | 1.1 GB | 6.2MB | 1.1 GB | 1% | vfat |

No mount inconsistencies detected. UUID-based references are used in `/etc/fstab`.

---

## 8. Readiness Status

| Layer | Status | Notes |
|-------|--------|-------|
| Base OS | ✅ Ready | Fully patched Ubuntu 24.04.2 |
| Network Accessibility | ✅ SSH enabled | No other services exposed |
| Application Stack | ⛔ Not installed | Intentionally clean system |
| Dev Disk Mounts | ⚠️ Unmounted | `/dev/sdb1` and `/dev/sdc1` are idle |
| Python Environment | ✅ Ready (3.12.3) | Good base for CLI testing |
| Node/npm Stack | ❌ Not present | Can be installed if required |

---

## 9. Testing Framework Recommendations

### Core Testing Infrastructure

#### Phase 1: Essential Testing Tools

```bash
# Update system and install core testing dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget build-essential

# Install Node.js for web testing
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker for containerized testing
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker agent0
```

#### Phase 2: Python Testing Environment

```bash
# Install Python testing frameworks
pip3 install --user pytest pytest-asyncio pytest-cov
pip3 install --user requests httpx aiohttp
pip3 install --user selenium webdriver-manager
pip3 install --user locust  # For load testing
pip3 install --user pytest-xdist  # For parallel testing
```

#### Phase 3: Storage Configuration for Testing

```bash
# Format and mount test data disks
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.ext4 /dev/sdc1
sudo mkdir -p /test-data /test-archive
sudo mount /dev/sdb1 /test-data
sudo mount /dev/sdc1 /test-archive
sudo chown -R agent0:agent0 /test-data /test-archive

# Add to fstab for persistence
echo "/dev/sdb1 /test-data ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "/dev/sdc1 /test-archive ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

### Testing Categories & Tools

#### Unit & Integration Testing

| Tool | Purpose | Installation |
|------|---------|--------------|
| pytest | Python unit testing | `pip3 install pytest` |
| pytest-asyncio | Async testing | `pip3 install pytest-asyncio` |
| pytest-cov | Code coverage | `pip3 install pytest-cov` |
| unittest.mock | Mocking framework | Built-in Python |

#### Performance & Load Testing

| Tool | Purpose | Installation |
|------|---------|--------------|
| Locust | Load testing | `pip3 install locust` |
| Apache Bench | HTTP benchmarking | `sudo apt install apache2-utils` |
| wrk | Modern HTTP benchmark | `sudo apt install wrk` |
| sysbench | System performance | `sudo apt install sysbench` |

#### End-to-End Testing

| Tool | Purpose | Installation |
|------|---------|--------------|
| Selenium | Web automation | `pip3 install selenium` |
| Playwright | Modern web testing | `pip3 install playwright` |
| Cypress | E2E testing | `npm install -g cypress` |
| Postman CLI | API testing | `npm install -g @postman/newman` |

### Expected Port Configuration Post-Setup

| Port | Service | Purpose | Security |
|------|---------|---------|----------|
| 8089 | Locust Web UI | Load testing dashboard | Internal only |
| 9090 | Test results server | Test report hosting | Internal only |
| 4444 | Selenium Grid | Web testing hub | Internal only |
| 3000 | Test application | Staging applications | Internal only |
| 5432 | PostgreSQL (if needed) | Test database | Internal only |

---

## 10. Next Steps

### Immediate Setup (High Priority)

1. **Configure Test Storage**
   - Format `/dev/sdb1` and `/dev/sdc1` to ext4
   - Mount as `/test-data` and `/test-archive`
   - Setup proper permissions and fstab entries

2. **Install Core Testing Stack**
   - Node.js and npm for web testing
   - Docker for containerized test environments
   - Essential Python testing libraries

### Testing Infrastructure Setup (Medium Priority)

1. **Automated Testing Pipeline**
   - Setup CI/CD tools (Jenkins/GitLab CI)
   - Configure test result reporting
   - Implement test data management

2. **Performance Testing Setup**
   - Install and configure Locust
   - Setup system monitoring during tests
   - Create performance baseline metrics

### Integration with Citadel-X Infrastructure

#### Test Targets

| Server | IP Address | Test Focus |
|--------|------------|------------|
| CX-Web | 192.168.10.38 | OpenWebUI functionality, UI testing |
| CX-API Gateway | 192.168.10.39 | API routing, load balancing |
| CX-LLM & Orchestration | 192.168.10.31 | Model inference, orchestration logic |
| CX-Metric | 192.168.10.30 | Monitoring system validation |

#### Testing Scenarios

1. **Unit Tests**
   - Individual component validation
   - Model inference accuracy
   - API endpoint functionality

2. **Integration Tests**
   - Cross-server communication
   - End-to-end workflow validation
   - Data flow verification

3. **Performance Tests**
   - Load testing API endpoints
   - Concurrent user simulation
   - System resource utilization

4. **Regression Tests**
   - Automated nightly test runs
   - Backward compatibility validation
   - Performance regression detection

### Test Data Management Strategy

#### Directory Structure

```text
/test-data/
├── datasets/          # Test datasets for ML models
├── fixtures/          # Test fixtures and mock data
├── results/           # Current test run results
├── reports/           # Generated test reports
└── configs/           # Test configuration files

/test-archive/
├── historical/        # Historical test results
├── baselines/         # Performance baselines
├── releases/          # Release-specific test artifacts
└── backups/           # Test data backups
```

#### Test Environment Isolation

- **Network Isolation:** Dedicated test VLAN or subnet
- **Data Isolation:** Separate test databases and storage
- **Service Isolation:** Containerized test services
- **Resource Isolation:** Memory and CPU limits for test processes

---

## Testing Server Specifications

**Optimal Use Cases:**

- Comprehensive regression testing of Citadel-X infrastructure
- Performance and load testing of API services
- End-to-end workflow validation
- Parallel test execution with high concurrency
- Large-scale data processing test scenarios

**Resource Allocation:**

- **CPU:** 12-core Xeon enables parallel test execution
- **Memory:** 125 GiB supports multiple concurrent test processes
- **Storage:** 7.2 TB total for extensive test data and archives
- **Network:** Isolated testing environment with access to all infrastructure

**Status:** Ready for comprehensive testing framework deployment - exceptional hardware foundation with clean baseline established.
