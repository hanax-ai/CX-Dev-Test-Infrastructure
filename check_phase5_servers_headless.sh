#!/bin/bash

declare -A servers=(
  ["192.168.10.30"]="hx-vector-database-server"
  ["192.168.10.35"]="hx-sql-database-server"
  ["192.168.10.38"]="hx-web-server"
  ["192.168.10.39"]="hx-api-gateway-server"
)

echo "Running headless SSH hostname checks..."

for ip in "${!servers[@]}"; do
  expected_hostname=${servers[$ip]}
  echo "→ Connecting to $ip (expecting: $expected_hostname)..."

  hostname_output=$(ssh -o ConnectTimeout=5 -o BatchMode=yes agent0@$ip 'hostname' 2>/dev/null)

  if [[ "$hostname_output" == "$expected_hostname" ]]; then
    echo "✅ $ip: Hostname is correct ($hostname_output)."
  elif [[ -z "$hostname_output" ]]; then
    echo "❌ $ip: SSH connection failed or host unreachable."
  else
    echo "❌ $ip: Connected but hostname mismatch. Got: $hostname_output"
  fi
done
