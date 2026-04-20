resource "proxmox_virtual_environment_container" "ai_lab" {
  node_name = "ryzen"
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
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
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

  # --- PROVISIONING GPU + OLLAMA ---
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      host     = var.pve_host_ip
      password = var.pve_root_password
    }

    inline = [
      # Configuration GPU sur l'hôte en utilisant l'ID variable
      "echo 'lxc.cgroup2.devices.allow: c 226:128 rwm' >> /etc/pve/lxc/${var.ai_lxc_id}.conf",
      "echo 'lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file' >> /etc/pve/lxc/${var.ai_lxc_id}.conf",
      "pct rescan",
      
      # Installation Ollama via pct exec
      "pct exec ${var.ai_lxc_id} -- bash -c 'apt-get update && apt-get install -y curl'",
      "pct exec ${var.ai_lxc_id} -- bash -c 'curl -fsSL https://ollama.com/install.sh | sh'",
      
      # Préchauffage : Téléchargement de Llama3 (ajuste selon ton envie)
      "pct exec ${var.ai_lxc_id} -- bash -c 'ollama run llama3 --version'"
    ]
  }
}