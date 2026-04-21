resource "proxmox_virtual_environment_container" "ai_lab" {
  node_name = var.pve_node
  vm_id     = var.ai_lxc_id

  initialization {
    hostname = var.ai_lxc_hostname
    ip_config {
      ipv4 {
        address = var.ai_lxc_ip
        gateway = var.gw_ip
      }
    }
    user_account {
      password = var.ai_lxc_password
    }
  }

  cpu {
    cores = 8
  }

  memory {
    dedicated = var.ai_lxc_memory
    swap      = var.ai_lxc_swap
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.ai_lxc_root_size
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = var.ai_lxc_mac
  }

  unprivileged = false
  features {
    nesting = true
  }

}