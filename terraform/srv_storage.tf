resource "proxmox_virtual_environment_container" "srv_storage" {
  node_name = var.pve_node
  vm_id     = var.storage_ct_id

  initialization {
    hostname = var.storage_ct_hostname
    ip_config {
      ipv4 {
        address = var.storage_ct_ip
        gateway = var.gw_ip
      }
    }
    user_account {
      keys = [file("~/.ssh/id_rsa.pub")]
      password = var.storage_ct_root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    # On pointe vers le template debian sur le stockage défini
    #template_file_id = proxmox_virtual_environment_file.debian_container_template.id
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.storage_root_size
  }

  mount_point {
    volume = var.storage_mount_host
    path   = var.storage_mount_dest
  }
  
  unprivileged = true
}
