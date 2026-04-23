terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  #api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  username = "root@pam" 
  password = var.pve_root_password 
  
  insecure = true

  ssh {
    agent = true
  }
}