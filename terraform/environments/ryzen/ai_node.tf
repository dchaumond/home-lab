module "ai_node" {
  source = "../../modules/lxc"

  node_name           = local.secrets.pve_node_ryzen
  vm_id               = local.secrets.ai_node.ct_id      # 409
  hostname            = local.secrets.ai_node.hostname  # ai-node
  tags                = ["ai", "gpu", "hsa"]

  os_template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  os_type             = "ubuntu"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = 100  # Stockage pour datasets

  ip_configs = [{
    ipv4 = {
      address = local.secrets.ai_node.ip      # 192.168.1.49/24
      gateway = local.secrets.gw_ip
    }
  }]

  network_interfaces = [{
    name   = "eth0"
    bridge = "vmbr0"
  }]

  unprivileged = false

  features = {
    nesting = true
  }

  cpu_cores       = 8    # Ressources pour GPU/IA
  memory_dedicated = 28672  # 28 Go RAM
  memory_swap      = 2048  # 2 Go swap
}