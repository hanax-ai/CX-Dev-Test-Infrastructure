#!/usr/bin/env python3
import subprocess
import requests

def run_ssh_cmd(ip, cmd):
    try:
        result = subprocess.run(f"ssh agent0@{ip} '{cmd}'", shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip() if result.returncode == 0 else f"Error: {result.stderr.strip()}"
    except subprocess.TimeoutExpired:
        return "Timeout"
    except Exception as e:
        return f"Error: {e}"

def test_http(url):
    try:
        response = requests.get(url, timeout=5)
        return f"✅ HTTP {response.status_code} - Service responding"
    except Exception as e:
        return f"❌ HTTP Error: {e}"

def main():
    ip = "192.168.10.38"
    print(f"🔍 Web Server Status Check ({ip})")
    print("=" * 50)
    
    print("🖥️  Server Info:")
    print(f"   Hostname: {run_ssh_cmd(ip, 'hostname')}")
    print(f"   Uptime: {run_ssh_cmd(ip, 'uptime -p')}")
    
    print("\n📦 Docker Status:")
    print(f"   Version: {run_ssh_cmd(ip, 'docker --version')}")
    print(f"   Container: {run_ssh_cmd(ip, 'docker ps --format \"{{.Names}} ({{.Status}})\"')}")
    
    print("\n🌐 Network Status:")
    print(f"   Port 3000: {run_ssh_cmd(ip, 'ss -tuln | grep :3000')}")
    print(f"   HTTP Test: {test_http(f'http://{ip}:3000')}")

if __name__ == "__main__":
    main()
