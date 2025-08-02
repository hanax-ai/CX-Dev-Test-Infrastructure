#!/usr/bin/env python3
import subprocess
import paramiko
import socket

# Server Configuration
remote_host = "192.168.10.38"
remote_user = "agent0"
webui_port = 3000

# SSH Command Runner
def ssh_run(cmd):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(remote_host, username=remote_user, timeout=10)
        stdin, stdout, stderr = ssh.exec_command(cmd)
        return stdout.read().decode().strip(), stderr.read().decode().strip()
    except Exception as e:
        return "", f"Error: {e}"
    finally:
        ssh.close()

# Check Port Accessibility
def is_port_open(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(2)
        return sock.connect_ex((host, port)) == 0

# Main Check
print(f"🔍 Checking HX-Web-Server ({remote_host}) for OpenWebUI status...\n")

cmds = {
    "🖥️ Hostname": "hostname",
    "🌐 IP Address": "hostname -I | awk '{print $1}'",
    "🕒 Uptime": "uptime -p",
    "⚙️ CPU": "lscpu | grep 'Model name' | awk -F: '{print $2}'",
    "🧠 Memory": "free -h",
    "💽 Disk Usage": "df -h /",
    "🐍 Python 3.12": "python3.12 --version",
    "🧬 Node.js": "node -v",
    "📦 NPM": "npm -v",
    "🐳 Docker Version": "docker --version",
    "📦 Running Containers": "docker ps --format '{{.Names}}\t{{.Status}}'",
    "🔹 OpenWebUI Container": "docker ps --filter 'ancestor=openwebui/openwebui' --format '{{.Names}}'"
}

for label, command in cmds.items():
    out, err = ssh_run(command)
    if err:
        print(f"{label}: ❌ {err.strip()}")
    else:
        print(f"{label}: {out.strip()}")

# Port check
port_open = is_port_open(remote_host, webui_port)
print(f"🔌 Port {webui_port} Reachable: {'✅ Yes' if port_open else '❌ No'}")

# Web UI availability
import requests
try:
    resp = requests.get(f"http://{remote_host}:{webui_port}", timeout=5)
    if resp.status_code == 200:
        print(f"🌍 OpenWebUI Web Interface: ✅ HTTP {resp.status_code} OK")
    else:
        print(f"🌍 OpenWebUI Web Interface: ❌ HTTP {resp.status_code}")
except Exception as e:
    print(f"🌍 OpenWebUI Web Interface: ❌ {e}")
