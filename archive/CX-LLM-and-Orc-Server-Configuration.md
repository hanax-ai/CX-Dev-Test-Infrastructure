# AI Server Configuration and Deployment Guide for Citadel Eco-System

**Date:** July 26, 2025
**Author:** Citadel AI Engineer
**Purpose:** To provide a comprehensive, step-by-step guide for configuring and deploying AI development environments on Ubuntu 24.04 LTS servers within the Citadel AI Eco-System, ensuring full reproducibility.

## Table of Contents

1. [System Configuration Summary](#1-system-configuration-summary)
   - [1.1 Server Hardware Layout](#11-server-hardware-layout)
   - [1.2 Unique Differences between Servers](#12-unique-differences-between-servers)
   - [1.3 Storage Configuration](#13-storage-configuration)
2. [Step-by-Step Installation Instructions](#2-step-by-step-installation-instructions)
   - [2.1 Initial System Preparation and NVIDIA Driver Installation](#21-initial-system-preparation-and-nvidia-driver-installation)
   - [2.2 CUDA Toolkit Installation](#22-cuda-toolkit-installation)
   - [2.3 cuDNN Installation](#23-cudnn-installation-via-local-repository-for-cuda-12)
   - [2.4 Conda (Miniconda) Setup](#24-conda-miniconda-setup)
   - [2.5 AI Development Environment Setup](#25-ai-development-environment-ai_env-setup)
   - [2.6 PyTorch and TensorFlow Installation](#26-pytorch-and-tensorflow-installation)
3. [Important Notes and Constraints](#3-important-notes-and-constraints)

---

## 1. System Configuration Summary

This section outlines the hardware and base OS configuration for each server in the Citadel AI Eco-System. All servers are running Ubuntu 24.04 LTS.

### 1.1. Server Hardware Layout

| Server Name | IP Address | Role | GPUs (Model & Quantity) | Storage Mounts | NICs (Configuration) |
|-------------|------------|------|------------------------|----------------|---------------------|
| Server Name | IP Address | Role | GPUs (Model & Quantity) | Storage Mounts | NICs (Configuration) |
|-------------|------------|------|------------------------|----------------|---------------------|
| hx-orc-server | 192.168.10.31 | Orchestration | 1x NVIDIA GeForce RTX 5060 Ti | See Storage Config 1.3 | To be defined |
| hx-llm-server-01 | 192.168.10.29 | LLM Server | 2x NVIDIA GeForce RTX 4070 Ti SUPER | See Storage Config 1.3 | To be defined |
| hx-llm-server-02 | 192.168.10.28 | LLM Server | 2x NVIDIA GeForce RTX 5060 Ti | To be defined | To be defined |

**Operating System:** Ubuntu 24.04 LTS (Noble Numbat) on all servers.

**Networking:** All servers are configured with static IP addresses as listed above and have their respective hostnames set. (Specific network settings for NICs like subnet mask, gateway, DNS are assumed to be pre-configured as per your network design).

### 1.2. Unique Differences between Servers

- **hx-orc-server:** Contains a single NVIDIA GeForce RTX 5060 Ti GPU. Primarily serves as the Orchestration Hub.
- **hx-llm-server-01:** Contains two NVIDIA GeForce RTX 4070 Ti SUPER GPUs. Dedicated to LLM workloads.
- **hx-llm-server-02:** Contains two NVIDIA GeForce RTX 5060 Ti GPUs. Dedicated to LLM workloads.

Despite the GPU model differences between hx-llm-server-01 and hx-llm-server-02, the installation process outlined below is universally applicable and has been validated to function correctly across these configurations.

### 1.3. Storage Configuration

#### Orchestration Server (hx-orc-server)

**hx-orc-server Storage Configuration Summary**
**Date:** July 26, 2025
**Server Role:** Orchestration Server for Citadel AI Eco-System

This server's storage has been configured to optimize for its role, leveraging both high-performance NVMe SSD and traditional Hard Disk Drives (HDDs) managed with Logical Volume Management (LVM) for flexibility and scalability.

##### 1. Physical Disks and Logical Volume Groups

**Primary OS Drive:** 1x 4TB NVMe SSD (`/dev/nvme0n1`).

This drive is fully utilized, with its main partition (`/dev/nvme0n1p3`) allocated to the `ubuntu-vg` LVM Volume Group.

**Secondary Storage Drives:** 2x 640GB HDDs (`/dev/sda`, `/dev/sdb`).

Both HDDs are collectively part of a separate LVM Volume Group named `vg0`.

##### 2. Configured Mount Points and Purposes

| Mount Point | Underlying LVM Logical Volume | Total Size | Purpose |
|-------------|------------------------------|------------|---------|
| `/` | `/dev/mapper/ubuntu--vg-ubuntu--lv` | 3.6 TB | Main Operating System and core applications. This logical volume has been extended to utilize the full 4TB NVMe drive capacity. |
| `/opt/ollama_models` | `/dev/mapper/vg0-ollama_lv` | 541 GB | Dedicated storage for Ollama AI models and associated downloads. |
| `/data/backups_and_logs` | `/dev/mapper/vg0-backups_logs_lv` | 632 GB | General storage for system backups and application logs. |

##### 3. Key Configuration Details

- **LVM Utilization:** LVM is extensively used for flexible storage management on both the NVMe SSD (for `/`) and the HDDs (for `/opt/ollama_models` and `/data/backups_and_logs`).
- **Filesystem Type:** All newly created logical volumes are formatted with ext4 filesystem.
- **Automounting:** All listed mount points are configured in `/etc/fstab` to ensure automatic mounting upon system boot.
- **Ownership:** Directory ownership for `/opt/ollama_models` and `/data/backups_and_logs` is set to `agent0:agent0` to ensure proper read/write permissions for the primary user.

#### LLM Server 01 (hx-llm-server-01)

**hx-llm-server-01 Storage Configuration Summary**  
**Date:** July 26, 2025  
**Server Role:** LLM Server for Citadel AI Eco-System

This server's storage is configured to provide a high-performance and high-capacity environment, leveraging its NVMe SSDs and a large HDD for optimized LLM workloads.

##### 1. Physical Disks and Partitioning

**Primary OS Drive (`/dev/nvme0n1`):** 1x 4TB NVMe SSD.

The primary OS partition (`/dev/mapper/ubuntu--vg-ubuntu--lv`) has been successfully extended using LVM to consume its full 3.6TB usable capacity.

**Dedicated Models Drive (`/dev/nvme0n1p1`):** 1x 4TB NVMe SSD.

This is a separate NVMe SSD partition (`/dev/nvme0n1p1`) that was specifically formatted as ext4 and is dedicated to AI models. (Note: The blkid output showed this as nvme0n1p1 with ext4 type, while the vfat EFI partition was on nvme1n1p1).

**Bulk Storage Drive (`/dev/sda1`):** 1x 8TB HDD.

This large HDD partition (`/dev/sda1`) was formatted as ext4 to provide substantial capacity for bulk data.

##### 2. Configured Mount Points and Purposes

| Mount Point | Underlying Device/Logical Volume | Total Size | Purpose |
|-------------|----------------------------------|------------|---------|
| `/` | `/dev/mapper/ubuntu--vg-ubuntu--lv` | 3.6 TB | Main Operating System and core applications. Leverages full NVMe speed. |
| `/opt/ai_models` | `/dev/nvme0n1p1` | 3.6 TB | High-speed storage for active AI models and frequently accessed datasets. |
| `/data/llm_bulk_storage` | `/dev/sda1` | 7.3 TB | Large capacity storage for backups, logs, and temporary large file results. |
| `/boot` | `/dev/nvme0n1p2` | 2.0 GB | Standard boot partition. |
| `/boot/efi` | `/dev/nvme1n1p1` | 1.1 GB | EFI System Partition (identified as a VFAT partition on the second NVMe). |

##### 3. Key Configuration Details

- **LVM Utilization:** LVM is used for the primary OS partition (`/`) on nvme0n1. The vg0 Volume Group (which existed on hx-orc-server) was not present or used for `/dev/sda` and `/dev/sdb` on this server; instead, raw partitions were formatted and mounted directly.
- **Filesystem Type:** All significant data partitions (`/`, `/opt/ai_models`, `/data/llm_bulk_storage`, `/boot`) are formatted with ext4. `/boot/efi` is vfat.
- **Automounting:** All listed mount points are configured in `/etc/fstab` to ensure automatic mounting upon system boot.
- **Ownership:** Directory ownership for `/opt/ai_models` and `/data/llm_bulk_storage` is set to `agent0:agent0` to ensure proper read/write permissions for the primary user.

#### LLM Server 02 (hx-llm-server-02)

*Storage configuration to be defined.*

---

## 2. Step-by-Step Installation Instructions

This section provides the precise chronological sequence of commands and operations for a fresh Ubuntu 24.04 LTS installation to a fully functional AI development environment.

### Important Considerations Before You Begin

- Ensure you have sudo privileges on the server.
- An active internet connection is required for downloading packages.
- It is assumed the OS is a fresh installation with minimal prior configuration.
- This guide hardcodes nvidia-driver-575-open.

### 2.1. Initial System Preparation and NVIDIA Driver Installation

This covers verifying your GPU and installing the specified NVIDIA open kernel module drivers.

#### Check for NVIDIA GPU

This command lists PCI devices and filters for NVIDIA.

```bash
lspci | grep -i nvidia
```

**Validation:** Confirm your NVIDIA GPU(s) are listed. Example output:

- **hx-orc-server:** `01:00.0 VGA compatible controller: NVIDIA Corporation GA102 [GeForce RTX 5060 Ti]`
- **hx-llm-server-01:** `01:00.0 VGA compatible controller: NVIDIA Corporation AD104 [GeForce RTX 4070 Ti SUPER]`
- **hx-llm-server-02:** `01:00.0 VGA compatible controller: NVIDIA Corporation GA102 [GeForce RTX 5060 Ti]`

#### Ensure Kernel Headers are Installed

DKMS requires kernel headers to build driver modules.

```bash
sudo apt update
sudo apt install -y linux-headers-$(uname -r)
```

**Validation:** Ensure installation completes without errors.

#### Blacklist Nouveau (Open-Source NVIDIA Driver)

This prevents conflicts with the proprietary NVIDIA driver. A reboot is necessary for this to take effect.

```bash
sudo sh -c "echo 'blacklist nouveau\noptions nouveau modeset=0' > /etc/modprobe.d/blacklist-nouveau.conf"
sudo update-initramfs -u
```

**Validation:** Commands should execute successfully.

#### Reboot System to Apply Nouveau Blacklist

```bash
sudo reboot
```

**Validation:** After reboot, log back in.

#### Enable Restricted and Multiverse Repositories

These repositories are necessary for the NVIDIA drivers.

```bash
sudo add-apt-repository restricted
sudo add-apt-repository multiverse
sudo apt update
```

**Validation:** `sudo apt update` should complete successfully.

#### Install NVIDIA Driver 575 (Open Kernel Module) and Utilities

This command installs the specific 575-open driver, its user-space utilities, and the NVIDIA settings tool.

```bash
sudo apt install -y nvidia-driver-575-open nvidia-utils-575-open nvidia-settings
```

**Validation:** The installation should complete successfully.

#### Reboot Your System

A second reboot is essential for the NVIDIA driver to fully take effect.

```bash
sudo reboot
```

**Validation:** After reboot, log back in.

#### Verify NVIDIA Driver Installation

```bash
nvidia-smi
```

**Validation:** You should see a table displaying your GPU(s), Driver Version: 575.64.03, and CUDA Version: 12.9.

#### Check Loaded Kernel Modules (Optional for Open Driver)

```bash
lsmod | grep nvidia
```

**Validation:** You should see nvidia_modeset, nvidia_uvm, nvidia_drm, and nvidia listed.

### 2.2. CUDA Toolkit Installation

This section details the installation of the NVIDIA CUDA Toolkit.

#### Install Essential Prerequisites for CUDA

```bash
sudo apt update
sudo apt install -y build-essential gcc dirmngr ca-certificates software-properties-common apt-transport-https curl
```

**Validation:** All packages should install successfully.

#### Download and Install NVIDIA CUDA GPG Keyring

This adds the NVIDIA repository's public key to your system's trusted sources.

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
```

**Validation:** Commands should execute without errors.

#### Update APT Cache

This refreshes your package list to include packages from the new NVIDIA CUDA repository.

```bash
sudo apt update
```

**Validation:** You should see the NVIDIA CUDA repository being listed and updated.

#### Install CUDA Toolkit

This installs the full CUDA Toolkit, including compilers, libraries, and development tools.

```bash
sudo apt -y install cuda-toolkit
```

**Validation:** Installation might take some time; ensure it completes successfully.

#### Set Up CUDA Environment Variables Permanently

These lines append the necessary CUDA paths to your ~/.bashrc for permanent system recognition.

```bash
echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
source ~/.bashrc
```

**Validation:** Close and reopen your terminal or run `source ~/.bashrc`. Then, verify the paths:

```bash
echo $PATH
echo $LD_LIBRARY_PATH
```

You should see `/usr/local/cuda/bin` at the beginning of your PATH and `/usr/local/cuda/lib64` at the beginning of your LD_LIBRARY_PATH.

#### Verify CUDA Installation

```bash
nvcc --version
```

**Validation:** Output should be `Cuda compilation tools, release 12.9, V12.9.86`.

### 2.3. cuDNN Installation (via Local Repository for CUDA 12)

This section installs cuDNN 9.11.0 specifically for CUDA 12 using the NVIDIA local repository method. Note that cuDNN samples were NOT installed as part of this process.

#### Download the cuDNN Local Repository Installer

```bash
wget https://developer.download.nvidia.com/compute/cudnn/9.11.0/local_installers/cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
```

**Validation:** Confirm the file exists:

```bash
ls cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
```

#### Install the Local Repository Package

```bash
sudo dpkg -i cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
```

**Validation:** Command should execute successfully, noting the GPG key step.

#### Copy the cuDNN GPG Keyring

```bash
sudo cp /var/cudnn-local-repo-ubuntu2404-9.11.0/cudnn-*-keyring.gpg /usr/share/keyrings/
```

**Validation:** Confirm the file was copied:

```bash
ls /usr/share/keyrings/cudnn-*-keyring.gpg
```

#### Update APT Package List

```bash
sudo apt update
```

**Validation:** You should see the local cuDNN repository being read and updated.

#### Install cuDNN for CUDA 12

```bash
sudo apt -y install cudnn-cuda-12
```

> **Note:** This command installs cudnn9-cuda-12 and its necessary runtime and development dependencies.

**Validation:** Installation should complete successfully.

#### Verify cuDNN Installation (APT Paths)

When installed via apt, cuDNN libraries are typically in `/usr/lib/x86_64-linux-gnu/` and headers in `/usr/include/`.

```bash
dpkg -L cudnn9-cuda-12 libcudnn9-cuda-12 libcudnn9-dev-cuda-12 libcudnn9-headers-cuda-12 | grep -E "libcudnn|cudnn.h"
```

**Validation:** Output should show paths to libcudnn files and cudnn.h under system directories, not `/usr/local/cuda/`.

### 2.4. Conda (Miniconda) Setup

Miniconda is essential for managing Python environments and dependencies for AI development.

#### Download the Miniconda Installer

```bash
cd /tmp
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```

**Validation:** `ls Miniconda3-latest-Linux-x86_64.sh` should show the file.

#### Run the Miniconda Installer Script

```bash
bash Miniconda3-latest-Linux-x86_64.sh
```

#### Follow Prompts Carefully

1. Press ENTER to review the license, then type `yes` and press ENTER to accept.
2. Press ENTER to confirm the default installation location (`/home/youruser/miniconda3`).
3. When asked "Do you wish the installer to initialize Miniconda3 by running conda init?", type `yes` and press ENTER.

**Validation:** Installer should complete with a message about conda init.

#### Activate Miniconda and Verify Installation

```bash
source ~/.bashrc
```

**Validation:** Your terminal prompt should change to `(base)`.

Verify Conda functionality:

```bash
conda --version
conda info --envs
```

#### Accept Anaconda Terms of Service

This is a mandatory step for using Anaconda's main channel.

```bash
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
```

**Validation:** Type `a` (for accept) and press ENTER when prompted.

### 2.5. AI Development Environment (ai_env) Setup

Create a dedicated Conda environment for PyTorch and TensorFlow, using Python 3.10 for optimal compatibility.

#### Deactivate base environment

```bash
conda deactivate
```

**Validation:** Your prompt should return to a non-Conda state.

#### Create New Conda Environment (ai_env) with Python 3.10

```bash
conda create -n ai_env python=3.10 -y
```

**Validation:** The environment creation should complete successfully without prompts.

#### Activate the ai_env

```bash
conda activate ai_env
```

**Validation:** Your command prompt should now display `(ai_env)`.

### 2.6. PyTorch and TensorFlow Installation

Install the deep learning frameworks within the active ai_env.

#### Install PyTorch with CUDA 12.8 Support (using pip)

This pip command installs PyTorch components explicitly compiled for CUDA 12.8, which is compatible with your CUDA 12.9 Toolkit.

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
```

**Validation:** Installation output should show `Successfully installed ... torch-2.7.1+cu128 ...`.

#### Verify PyTorch CUDA Installation

```bash
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.cuda.device_count()); print(torch.cuda.get_device_name(0))"
```

**Validation:**

- Expected output for hx-orc-server and hx-llm-server-02: `2.7.1+cu128`, `True`, `1` (or `2` for llm-server-02), and `NVIDIA GeForce RTX 5060 Ti`.
- Expected output for hx-llm-server-01: `2.7.1+cu128`, `True`, `2`, and `NVIDIA GeForce RTX 4070 Ti SUPER`.

#### Install TensorFlow with GPU Support (using pip)

```bash
pip install tensorflow[and-cuda]
```

**Validation:** Installation should complete successfully.

#### Verify TensorFlow GPU Installation

```bash
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU')); print(tf.constant([[1.0, 2.0], [3.0, 4.0]]) @ tf.constant([[1.0, 2.0], [3.0, 4.0]]))"
```

**Validation:**

- Output should list your GPU(s) (e.g., `[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]` for hx-orc-server, or `[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU'), PhysicalDevice(name='/physical_device:GPU:1', device_type='GPU')]` for LLM servers).
- The matrix multiplication should execute and print a tensor result.

> **Important Note:** Warnings like "Unable to register cuFFT/cuDNN/cuBLAS factory" or "TensorFlow was not built with CUDA kernel binaries compatible with compute capability X.X. CUDA kernels will be jit-compiled from PTX" are expected and do not prevent GPU functionality. TensorFlow will still leverage your GPUs.

---

## 3. Important Notes and Constraints

- **NVIDIA Driver Version:** This guide explicitly uses nvidia-driver-575-open. Do not attempt to install different driver versions without thorough compatibility checks.

- **cuDNN Samples:** No cuDNN samples were installed or validated as part of this specific process to keep the installation lean.

- **No Docker References:** This guide focuses solely on bare-metal installation and does not include any Docker-related configurations or commands.

- **Python Version:** Python 3.10 was chosen for the ai_env to ensure broad compatibility with stable PyTorch and TensorFlow releases. Avoid upgrading to Python 3.12 within this environment without verifying full framework support.

- **Conda Terms of Service:** Remember that `conda tos accept` is a new requirement and must be performed once per user per channel.

- **Compute Capability Warnings (TensorFlow):** The "TensorFlow was not built with CUDA kernel binaries compatible with compute capability X.X. CUDA kernels will be jit-compiled from PTX" warning is expected, especially for newer GPU architectures like your RTX 5060 Ti (compute capability 12.0). This means TensorFlow will compile kernels on-the-fly, which might incur a slight delay on the first execution of certain operations, but it does not prevent GPU utilization.
 
 

