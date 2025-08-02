#!/bin/bash

# SSH Key Deployment Script for Phase 5 Servers
# Run this after servers are provisioned with agent0 user accounts

SERVERS=(
  "192.168.10.30"
  "192.168.10.35" 
  "192.168.10.38"
  "192.168.10.39"
)

echo "🔑 Deploying SSH keys to Phase 5 servers..."
echo "Note: You'll be prompted for agent0 password on each server"
echo

for ip in "${SERVERS[@]}"; do
  echo "→ Copying SSH key to agent0@$ip..."
  
  if ssh-copy-id -i ~/.ssh/id_ed25519.pub agent0@$ip; then
    echo "✅ SSH key successfully deployed to $ip"
  else
    echo "❌ Failed to deploy SSH key to $ip"
  fi
  echo
done

echo "🧪 Testing connectivity after key deployment..."
./check_phase5_servers_headless.sh
