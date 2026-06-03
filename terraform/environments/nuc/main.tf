locals {
  secrets = jsondecode(file("${path.module}/../../../.env.json"))
}

# Configuration du provider Proxmox pour le nœud NUC
provider "proxmox" {
  alias = "nuc"
  endpoint  = "https://${local.secrets.pve_host_nuc}:8006"
  username  = local.secrets.pve_user_nuc
  password  = local.secrets.pve_password_nuc
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}