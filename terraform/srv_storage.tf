resource "proxmox_virtual_environment_container" "srv_storage" {
  node_name = var.pve_node
  vm_id     = var.storage_ct_id

  features {
    nesting = true
    keyctl  = true
  }

  initialization {
    hostname = var.storage_ct_hostname
    ip_config {
      ipv4 {
        address = var.storage_ct_ip
        gateway = var.gw_ip
      }
    }
    user_account {
      keys     = [var.ssh_key_homelab]
      password = var.storage_ct_root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
    mac_address = var.storage_ct_mac_address
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
    volume = var.storage_mount_samba_host
    path   = var.storage_mount_samba_dest
  }

  mount_point {
    volume = var.storage_mount_minio_host
    path   = var.storage_mount_minio_dest
  }
  
  unprivileged = true

  lifecycle {
    ignore_changes = [
      initialization[0].user_account, # Empêche le remplacement si la clé ou le pass change
      initialization[0].ip_config     # Optionnel : évite le kill si tu changes d'IP
    ]
  }
}
