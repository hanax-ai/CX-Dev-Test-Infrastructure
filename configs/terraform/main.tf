# CX R&D Infrastructure - Terraform Configuration
# Main infrastructure definition for Citadel AI Operating System
# Updated: July 31, 2025

terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variables for CX Infrastructure
variable "cx_infrastructure_servers" {
  description = "Map of CX R&D Infrastructure servers"
  type = map(object({
    ip_address = string
    role       = string
    port       = number
  }))
  default = {
    "cx-web" = {
      ip_address = "192.168.10.28"
      role       = "web-server"
      port       = 80
    }
    "cx-api-gateway" = {
      ip_address = "192.168.10.29"
      role       = "api-gateway"
      port       = 8000
    }
    "cx-database" = {
      ip_address = "192.168.10.30"
      role       = "database"
      port       = 5432
    }
    "cx-vector-db" = {
      ip_address = "192.168.10.31"
      role       = "vector-database"
      port       = 6333
    }
    "cx-llm-orchestration" = {
      ip_address = "192.168.10.32"
      role       = "llm-orchestration"
      port       = 8080
    }
    "cx-test" = {
      ip_address = "192.168.10.33"
      role       = "test-server"
      port       = 3000
    }
    "cx-metric" = {
      ip_address = "192.168.10.34"
      role       = "metrics-monitoring"
      port       = 9090
    }
    "cx-dev" = {
      ip_address = "192.168.10.35"
      role       = "development"
      port       = 8080
    }
    "cx-devops" = {
      ip_address = "192.168.10.36"
      role       = "devops-cicd"
      port       = 8080
    }
  }
}

# Local file generation for dynamic configurations
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    servers = var.cx_infrastructure_servers
  })
  filename = "${path.module}/../ansible/inventory/dynamic_hosts"
}

# Generate server configuration files
resource "local_file" "server_configs" {
  for_each = var.cx_infrastructure_servers
  
  content = templatefile("${path.module}/templates/server_config.tpl", {
    server_name = each.key
    ip_address  = each.value.ip_address
    role        = each.value.role
    port        = each.value.port
  })
  filename = "${path.module}/server-configs/${each.key}.conf"
}

# Health check script generation
resource "local_file" "health_check_script" {
  content = templatefile("${path.module}/templates/health_check.tpl", {
    servers = var.cx_infrastructure_servers
  })
  filename = "${path.module}/../../scripts/health-check-generated.sh"
  file_permission = "0755"
}

# Output server information
output "cx_infrastructure_summary" {
  description = "Summary of CX R&D Infrastructure servers"
  value = {
    total_servers = length(var.cx_infrastructure_servers)
    servers = {
      for name, config in var.cx_infrastructure_servers : name => {
        ip      = config.ip_address
        role    = config.role
        port    = config.port
        url     = "http://${config.ip_address}:${config.port}"
      }
    }
  }
}

# Output for Ansible integration
output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}

# Generate deployment metadata
locals {
  deployment_metadata = {
    infrastructure_name = "CX R&D Infrastructure"
    deployment_date     = timestamp()
    terraform_version   = "1.12.2"
    total_servers       = length(var.cx_infrastructure_servers)
    environment         = "development"
    project             = "Citadel AI Operating System"
  }
}

# Save deployment metadata
resource "local_file" "deployment_metadata" {
  content = jsonencode(local.deployment_metadata)
  filename = "${path.module}/deployment-metadata.json"
}
