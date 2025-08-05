# HX R&D Infrastructure - Terraform Configuration
# Main infrastructure definition for Citadel AI Operating System
# Updated: August 4, 2025

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

# Infrastructure server map - Fully aligned with HX inventory
variable "hx_infrastructure_servers" {
  description = "Map of HX R&D Infrastructure servers"
  type = map(object({
    ip_address = string
    role       = string
    port       = number
  }))
  default = {
    "hx-web-server" = {
      ip_address = "192.168.10.38"
      role       = "web-ui"
      port       = 8080
    }
    "hx-api-gateway-server" = {
      ip_address = "192.168.10.39"
      role       = "api-gateway"
      port       = 8000
    }
    "hx-sql-database-server" = {
      ip_address = "192.168.10.35"
      role       = "database"
      port       = 5432
    }
    "hx-vector-db-server" = {
      ip_address = "192.168.10.30"
      role       = "vector-database"
      port       = 6333
    }
    "hx-llm-server-01" = {
      ip_address = "192.168.10.29"
      role       = "llm-server-chat"
      port       = 11434
    }
    "hx-llm-server-02" = {
      ip_address = "192.168.10.28"
      role       = "llm-server-instruct"
      port       = 11434
    }
    "hx-orchestration-server" = {
      ip_address = "192.168.10.31"
      role       = "orchestration"
      port       = 8080
    }
    "hx-test-server" = {
      ip_address = "192.168.10.34"
      role       = "test"
      port       = 8080
    }
    "hx-dev-server" = {
      ip_address = "192.168.10.33"
      role       = "development"
      port       = 8080
    }
    "hx-dev-ops-server" = {
      ip_address = "192.168.10.36"
      role       = "devops"
      port       = 8080
    }
    "hx-metrics-server" = {
      ip_address = "192.168.10.37"
      role       = "metrics"
      port       = 9090
    }
  }
}

# Dynamic Ansible inventory generation
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    servers = var.hx_infrastructure_servers
  })
  filename = "${path.module}/../ansible/inventory/dynamic_hosts"
}

# Per-server configuration file generation
resource "local_file" "server_configs" {
  for_each = var.hx_infrastructure_servers

  content = templatefile("${path.module}/templates/server_config.tpl", {
    server_name = each.key
    ip_address  = each.value.ip_address
    role        = each.value.role
    port        = each.value.port
  })
  filename = "${path.module}/server-configs/${each.key}.conf"
}

# Auto-generated health check script
resource "local_file" "health_check_script" {
  content = templatefile("${path.module}/templates/health_check.tpl", {
    servers = var.hx_infrastructure_servers
  })
  filename = "${path.module}/../../scripts/health-check-generated.sh"
  file_permission = "0755"
}

# Output summary of infrastructure
output "hx_infrastructure_summary" {
  description = "Summary of HX R&D Infrastructure servers"
  value = {
    total_servers = length(var.hx_infrastructure_servers)
    servers = {
      for name, config in var.hx_infrastructure_servers : name => {
        ip      = config.ip_address
        role    = config.role
        port    = config.port
        url     = "http://${config.ip_address}:${config.port}"
      }
    }
  }
}

# Output Ansible inventory path
output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}

# Local deployment metadata
locals {
  deployment_metadata = {
    infrastructure_name = "HX R&D Infrastructure"
    deployment_date     = timestamp()
    terraform_version   = "1.12.2"
    total_servers       = length(var.hx_infrastructure_servers)
    environment         = "development"
    project             = "Citadel AI Operating System"
  }
}

# Save deployment metadata
resource "local_file" "deployment_metadata" {
  content  = jsonencode(local.deployment_metadata)
  filename = "${path.module}/deployment-metadata.json"
}
