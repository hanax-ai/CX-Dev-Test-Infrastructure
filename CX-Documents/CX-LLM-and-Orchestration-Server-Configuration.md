# CX-LLM and Orchestration Server Configuration

**Date:** July 27, 2025  
**Author:** Citadel AI Engineer

## Purpose

To provide a comprehensive, consolidated overview of the standardized AI development environment and storage configurations across the Citadel AI Eco-System servers. This document serves as the authoritative reference for deployment and operational understanding.

## Table of Contents

1. [Infrastructure Overview](#1-infrastructure-overview)
   - [1.1 Server Hardware and Role Summary](#11-server-hardware-and-role-summary)
2. [Standardized AI Software Stack](#2-standardized-ai-software-stack)
3. [Storage Configuration Summary](#3-storage-configuration-summary)
   - [3.1 hx-orc-server (Orchestration Node)](#31-hx-orc-server-orchestration-node)
   - [3.2 hx-llm-server-01 (CX-LLM Node 1)](#32-hx-llm-server-01-cx-llm-node-1)
   - [3.3 hx-llm-server-02 (CX-LLM Node 2)](#33-hx-llm-server-02-cx-llm-node-2)
4. [Engineering Notes and Best Practices](#4-engineering-notes-and-best-practices)

---

## 1. Infrastructure Overview

The Citadel AI Eco-System consists of three standalone servers, each independently configured with static IPs, GPU-accelerated compute environments, and optimized storage for AI workloads. All systems run Ubuntu 24.04 LTS (Noble Numbat) and share a harmonized software and storage stack to ensure operational consistency.

### 1.1. Server Hardware and Role Summary

| Server Name | IP Address | Role | GPU(s) | RAM | Primary OS Disk | Secondary Storage |
|-------------|------------|------|--------|-----|-----------------|-------------------|
| hx-orc-server | 192.168.10.36 | Orchestration | 1× RTX 5060 Ti | 64 GB | WD_BLACK SN7100 4TB (NVMe) | 2× WDC WD6400AAKS-6 (640GB HDD) |
| hx-llm-server-01 | 192.168.10.34 | CX-LLM Server | 2× RTX 4070 Ti SUPER | 128 GB | WD_BLACK SN7100 4TB (NVMe) | 1× ST8000DM004-2U91 (8TB HDD), 1× WD_BLACK SN850X 4TB (NVMe) |
| hx-llm-server-02 | 192.168.10.28 | CX-LLM Server | 2× RTX 5060 Ti | 64 GB | WD_BLACK SN7100 4TB (NVMe) | 1× Samsung SSD 870 (2TB SSD), 1× WDC WD101EFBX-68 (10TB HDD) |

**Operating System:** Ubuntu 24.04 LTS (Noble Numbat)  
**Network:** All servers use static IP addressing and defined hostnames.

---

## 2. Standardized AI Software Stack

Each server adheres to a unified software setup tailored for bare-metal deep learning workloads:

- **NVIDIA Driver Version:** 575.64.03 (nvidia-driver-575-open)
- **CUDA Toolkit:** Version 12.9 (Build: May 27, 2025, V12.9.86)
- **cuDNN:** 9.11.0.98-1 (installed from cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb)
- **Python Environment Manager:** Miniconda3 (installed per user in $HOME/miniconda3)
- **Dedicated Environment:** Conda environment ai_env with Python 3.10.18

**Deep Learning Frameworks within ai_env:**
- **PyTorch:** 2.7.1+cu128
- **TensorFlow:** 2.19.0

---

## 3. Storage Configuration Summary

Mount points use the ext4 filesystem and rely on UUID-based /etc/fstab entries for resilience. All custom paths are owned by agent0:agent0.

### 3.1. hx-orc-server (Orchestration Node)

| Mount Point | Device/Volume | Type | Size | Purpose |
|-------------|---------------|------|------|---------|
| `/` | `/dev/mapper/ubuntu--vg-ubuntu--lv` | NVMe SSD | 3.6 TB | Main OS and applications (full 4TB utilization) |
| `/opt/ai_models` | `/dev/mapper/vg0-ollama_lv` | HDD (LVM) | 541 GB | Ollama-compatible model storage |
| `/data/backups_and_logs` | `/dev/mapper/vg0-backups_logs_lv` | HDD (LVM) | 632 GB | Logs, backup archives |

#### Services and Configuration

**Ollama Model Runtime:**
- Ollama 0.9.6 installed
- Model storage directory: `/opt/ai_models`
- Exposed via network using `OLLAMA_HOST=0.0.0.0`
- Default port: 11434

**Embedding Models:**
- Deployed to `/opt/ai_models`
- Invoked by downstream LLM servers via API calls

**CUDA Enablement:**
- CUDA 12.9 installed via NVIDIA APT repository method
- nvcc available globally

**Orchestration Role:**
- Provides embedding generation and coordination services

**Future integration with:**
- Clerk
- Copilot Kit
- AG UI
- FastAPI Routing Gateway
- LiveKit signaling node

**API Routing Configuration (planned):**
- Central API proxy to fan out model requests
- Supports multiple Ollama backends with weighted routing or round-robin

### 3.2. hx-llm-server-01 (CX-LLM Node 1)
Mount Point	Device	Type	Size	Purpose
/	/dev/mapper/ubuntu--vg-ubuntu--lv	NVMe SSD	3.6 TB	OS and apps
/opt/ai_models	/dev/nvme0n1p1	NVMe SSD	3.6 TB	High-speed access for active models and datasets
/data/llm_bulk_storage	/dev/sda1	HDD	7.3 TB	Bulk storage: logs, backups, large dataset dumps
/boot/efi	/dev/nvme1n1p1	NVMe SSD	1.1 GB	EFI system partition

LLM Runtime Configuration:

Ollama Runtime:

Ollama 0.9.6 installed

Models pulled to /opt/ai_models

Default port 11434

Ollama bound to 0.0.0.0 for remote access

Model Deployment:

Confirmed models:

llama2

Nous Hermes 2 Mixtral 8x7B DPO

Phi-3 Mini 4K

DeepCoder-14B (future)

Ollama’s multi-model backend allows concurrent model hosting under one port

**API Gateway Strategy:**
- Future FastAPI gateway will route to internal Ollama by model ID
- Model registry expected via `/opt/ai_models/ollama_model_registry.json`

### 3.3. hx-llm-server-02 (CX-LLM Node 2)

| Mount Point | Device | Type | Size | Purpose |
|-------------|--------|------|------|---------|
| `/` | `/dev/mapper/ubuntu--vg-ubuntu--lv` | NVMe SSD | 3.6 TB | OS and system binaries |
| `/opt/ai_models` | `/dev/sda1` | SSD | 1.8 TB | Active LLM model storage on high-speed SSD |
| `/data/llm_archive` | `/dev/sdb1` | HDD | 9.1 TB | Archive storage for older models, datasets, and logs |

#### LLM Runtime Configuration

**Ollama Installed:**
- Runtime version 0.9.6 operational
- Shared model structure with hx-llm-server-01
- Model directory: `/opt/ai_models`

**Target Models:**
- IMP v1 3B
- Qwen Coder DeepSeek R1 14B
- Phi-3 Mini

Model pull tested and confirmed

**Integration:**
- Direct Ollama API endpoint: <http://192.168.10.28:11434>
- Gateway routing to be handled via orchestration node or API proxy

---

## 4. Engineering Notes and Best Practices

- **NVIDIA Driver Consistency:** All nodes pinned to 575.64.03 (nvidia-driver-575-open)
- **CUDA/cuDNN Consistency:** Identical CUDA 12.9 and cuDNN 9.11 stack across nodes
- **Python Isolation:** Only Conda-based ai_env should be used for AI packages
- **TensorFlow GPU Messages:** Benign JIT kernel notices can be ignored
- **fstab Robustness:** All mount points use UUIDs to prevent device mapping errors
- **User Permissions:** All custom mount paths owned by agent0:agent0
- **No Docker Policy:** All deployments use direct installation for full GPU visibility
