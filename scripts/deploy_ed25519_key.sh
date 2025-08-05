#!/bin/bash

# File: deploy_ed25519_key.sh
# Description: Propagate agent0's Ed25519 key to Citadel infrastructure nodes

set -euo pipefail

PUBLIC_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
USER="agent0"
KEY_CONTENT=$(cat "$PUBLIC_KEY_PATH")

HOSTS=(
  "192.168.10.28"  # hx-llm-server-02
  "192.168.10.29"  # hx-llm-server-01
  "192.168.10.30"  # hx-vector-database-server
  "192.168.10.31"  # hx-orchestration-server
  "192.168.10.33"  # hx-dev-server
  "192.168.10.34"  # hx-test-server
  "192.168.10.35"  # hx-sql-database-server
  "192.168.10.36"  # hx-dev-ops-server
  "192.168.10.38"  # hx-web-server
  "192.168.10.39"  # hx-api-gateway-server
)

echo "🚀 Starting key deployment..."
echo "📋 Key fingerprint: $(ssh-keygen -lf $PUBLIC_KEY_PATH | awk '{print $2}')"
echo "🔑 Deploying to ${#HOSTS[@]} hosts..."
echo ""

for HOST in "${HOSTS[@]}"; do
  echo "🔧 Deploying key to $HOST..."

  # Try SSH with timeout and different key options
  timeout 10 ssh -o ConnectTimeout=5 -o PasswordAuthentication=no -o PubkeyAuthentication=yes -i ~/.ssh/id_rsa "$USER@$HOST" bash -s <<EOF 2>/dev/null || \
  timeout 10 ssh -o ConnectTimeout=5 -o PasswordAuthentication=no -o PubkeyAuthentication=yes -i ~/.ssh/id_ed25519 "$USER@$HOST" bash -s <<EOF 2>/dev/null || \
  echo "❌ Failed to connect to $HOST (SSH failure or network unreachable)"
mkdir -p /home/$USER/.ssh
touch /home/$USER/.ssh/authorized_keys
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys
grep -qxF "$KEY_CONTENT" /home/$USER/.ssh/authorized_keys || echo "$KEY_CONTENT" >> /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh
echo "✅ Key deployed successfully to $HOST"
EOF

done

echo ""
echo "✅ SSH public key deployment completed."
echo "🧪 Run 'ansible all -i configs/ansible/inventory.yaml -m ping' to test connectivity"
