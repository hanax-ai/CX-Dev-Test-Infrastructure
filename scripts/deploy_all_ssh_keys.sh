#!/bin/bash

# Comprehensive SSH Key Deployment Script for CX R&D Infrastructure
# Deploy Ed25519 SSH keys to all servers requiring authentication

# Servers that need SSH key deployment based on validation results
UNREACHABLE_SERVERS=(
  "192.168.10.31"  # hx-llm-server-01
  "192.168.10.32"  # hx-llm-server-02
  "192.168.10.33"  # hx-orchestration-server
  "192.168.10.35"  # hx-dev-server
  "192.168.10.36"  # hx-test-server
  "192.168.10.37"  # hx-dev-ops-server
)

# Server hostnames for reference
declare -A SERVER_NAMES=(
  ["192.168.10.31"]="hx-llm-server-01"
  ["192.168.10.32"]="hx-llm-server-02"
  ["192.168.10.33"]="hx-orchestration-server"
  ["192.168.10.35"]="hx-dev-server"
  ["192.168.10.36"]="hx-test-server"
  ["192.168.10.37"]="hx-dev-ops-server"
)

echo "🔑 Phase 1 Remediation: SSH Key Deployment"
echo "=============================================="
echo "Deploying Ed25519 SSH keys to ${#UNREACHABLE_SERVERS[@]} servers..."
echo "Note: You'll be prompted for agent0 password on each server"
echo

# Check if Ed25519 key exists
if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
  echo "❌ Ed25519 public key not found at ~/.ssh/id_ed25519.pub"
  echo "Please generate one with: ssh-keygen -t ed25519 -C 'agent0@$(hostname)'"
  exit 1
fi

echo "✅ Ed25519 public key found: ~/.ssh/id_ed25519.pub"
echo

# Deploy keys to each server
SUCCESS_COUNT=0
FAILED_SERVERS=()

for ip in "${UNREACHABLE_SERVERS[@]}"; do
  hostname="${SERVER_NAMES[$ip]}"
  echo "→ Deploying key to $hostname ($ip)..."
  
  # Test basic connectivity first
  if ! ping -c 1 -W 3 "$ip" &>/dev/null; then
    echo "❌ $hostname ($ip): Network unreachable"
    FAILED_SERVERS+=("$ip")
    echo
    continue
  fi
  
  # Deploy SSH key
  if ssh-copy-id -i ~/.ssh/id_ed25519.pub -o ConnectTimeout=10 -o StrictHostKeyChecking=no agent0@$ip 2>/dev/null; then
    echo "✅ $hostname ($ip): SSH key deployed successfully"
    ((SUCCESS_COUNT++))
  else
    echo "❌ $hostname ($ip): Failed to deploy SSH key"
    FAILED_SERVERS+=("$ip")
  fi
  echo
done

echo "=============================================="
echo "🔑 SSH Key Deployment Summary"
echo "=============================================="
echo "✅ Successful deployments: $SUCCESS_COUNT/${#UNREACHABLE_SERVERS[@]}"

if [[ ${#FAILED_SERVERS[@]} -gt 0 ]]; then
  echo "❌ Failed deployments:"
  for ip in "${FAILED_SERVERS[@]}"; do
    echo "   - ${SERVER_NAMES[$ip]} ($ip)"
  done
  echo
fi

echo "🧪 Testing connectivity after key deployment..."
echo "=============================================="

# Test connectivity with Ansible
cd /opt/CX-Dev-Test-Infrastructure/configs/ansible
ansible all -m ping --one-line | grep -E "(SUCCESS|UNREACHABLE|FAILED)" | sort

echo
echo "🎯 Phase 1 Remediation Status:"
if [[ $SUCCESS_COUNT -eq ${#UNREACHABLE_SERVERS[@]} ]]; then
  echo "✅ All SSH keys deployed successfully - Phase 1 COMPLETE"
else
  echo "⚠️  Some deployments failed - Manual intervention may be required"
fi
