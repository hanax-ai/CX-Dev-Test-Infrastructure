#!/bin/bash

# Define target IPs and expected server hostnames
declare -A servers=(
  ["192.168.10.30"]="hx-vector-db-server"
  ["192.168.10.35"]="hx-sql-database-server"
  ["192.168.10.38"]="hx-web-server"
  ["192.168.10.39"]="hx-api-gateway-server"
)

echo "Checking Phase 5 Citadel Alpha servers..."

for ip in "${!servers[@]}"; do
  expected_hostname=${servers[$ip]}
  echo "Connecting to $ip (expecting $expected_hostname)..."

  # Attempt SSH and retrieve hostname
  ssh -o ConnectTimeout=5 -o BatchMode=yes agent0@$ip 'hostname' 2>/dev/null | grep "$expected_hostname" >/dev/null

  if [ $? -eq 0 ]; then
    echo "✅ $ip is reachable and hostname is correct ($expected_hostname)."
  else
    echo "❌ Connection to $ip failed or hostname mismatch!"
  fi
done
