import os
import platform
import socket
import subprocess

output_path = "/opt/gateway/system_info.txt"

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except:
        return "Unavailable"

with open(output_path, "w") as f:
    f.write("HOSTNAME:\n" + socket.gethostname() + "\n\n")
    f.write("IP ADDRESS:\n" + run_cmd("hostname -I | awk '{print $1}'") + "\n\n")
    f.write("OS & KERNEL:\n" + platform.platform() + "\n\n")
    f.write("UPTIME:\n" + run_cmd("uptime -p") + "\n\n")
    f.write("CPU MODEL:\n" + run_cmd("lscpu | grep 'Model name' | awk -F: '{print $2}'") + "\n\n")
    f.write("MEMORY:\n" + run_cmd("free -h") + "\n\n")
    f.write("DISK USAGE:\n" + run_cmd("df -h /") + "\n\n")
    f.write("OPEN PORTS (8000):\n" + (run_cmd("ss -tuln | grep ':8000'") or "Port 8000 not open") + "\n\n")
    f.write("VIRTUAL ENVIRONMENTS:\n" + run_cmd("find /opt/gateway -type d -name 'bin' -exec ls {}/activate \\; 2>/dev/null") + "\n\n")

print(f"✅ System info written to {output_path}")
