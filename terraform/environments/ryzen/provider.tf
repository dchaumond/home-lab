terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.105.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${local.secrets.pve_host_ryzen}:8006/api2/json"
  username = local.secrets.pve_user_ryzen
  password = local.secrets.pve_password_ryzen
  insecure = true
}