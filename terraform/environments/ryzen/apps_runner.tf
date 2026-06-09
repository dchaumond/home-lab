resource "proxmox_virtual_environment_container" "apps_runner" {
  node_name = local.secrets.pve_node_ryzen
  vm_id     = local.secrets.apps_runner_ryzen.ct_id

  initialization {
    hostname = local.secrets.apps_runner_ryzen.hostname
    ip_config {
      ipv4 {
        address = local.secrets.apps_runner_ryzen.ip
        gateway = local.secrets.gw_ip
      }
    }
    user_account {
      password = local.secrets.root_password
      keys     = [local.secrets.ssh_key_homelab]
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = local.secrets.apps_runner_ryzen.mem
  }

  disk {
    datastore_id = "local-lvm"
    size         = local.secrets.apps_runner_ryzen.disk
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  unprivileged = false
  features {
    nesting = true  // Pour Docker
  }
}