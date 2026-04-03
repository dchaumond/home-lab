resource "proxmox_virtual_environment_container" "srv_storage" {
  node_name = var.pve_node
  vm_id     = var.storage_ct_id

  initialization {
    hostname = var.storage_ct_hostname
    ip_config {
      ipv4 {
        address = var.storage_ct_ip
        gateway = var.storage_ct_gw
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

resource "local_file" "ansible_inventory" {
  content = <<EOT
[storage_servers]
${var.storage_ct_ip} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
EOT
  filename = "../ansible/inventory.ini"
}

output "debug_user" {
  value = var.pm_api_token_id
}