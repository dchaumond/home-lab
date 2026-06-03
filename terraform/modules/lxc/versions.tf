##############################################################
# Versions / Provider requirements du module LXC
##############################################################

terraform {
  required_version = ">= 1.3.0" # requis pour optional() dans les variables objet

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}
