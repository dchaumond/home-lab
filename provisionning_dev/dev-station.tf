resource "proxmox_virtual_environment_container" "dev_container" {
  node_name = var.pve_node
  vm_id     = var.dev_lxc_id

  initialization {
    hostname = var.dev_lxc_hostname

    ip_config {
      ipv4 {
        address = var.dev_lxc_ip
        gateway = var.gw_ip
      }
    }

    user_account {
      # Forcer le mot de passe root pour le futur accès RDP/Console
      password = var.dev_lxc_password
    }
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated =  var.dev_lxc_memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.dev_lxc_root_size
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
    mac_address = var.dev_lxc_mac
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-11-standard_11.7-1_amd64.tar.zst"    
    type             = "debian"
  }

  features {
    nesting = true
  }
}