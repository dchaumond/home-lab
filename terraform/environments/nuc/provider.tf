terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.105.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${local.secrets.pve_host_nuc}:8006/api2/json"
  username = local.secrets.pve_user_nuc
  password = local.secrets.pve_password_nuc
  insecure = true
}
