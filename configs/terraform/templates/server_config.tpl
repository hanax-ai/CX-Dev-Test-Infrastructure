# CX R&D Infrastructure Server Configuration
# Server: ${server_name}
# Role: ${role}
# Generated: ${timestamp()}

[server]
name = "${server_name}"
ip_address = "${ip_address}"
role = "${role}"
port = ${port}
url = "http://${ip_address}:${port}"

[deployment]
environment = "cx_rnd_infrastructure"
project = "Citadel AI Operating System"
managed_by = "terraform"

[monitoring]
health_check_endpoint = "http://${ip_address}:${port}/health"
metrics_endpoint = "http://${ip_address}:${port}/metrics"
