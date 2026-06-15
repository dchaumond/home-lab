module "apps_runner_ryzen" {
  source = "../../modules/lxc"

  node_name           = "pve-ryzen"
  vm_id               = local.secrets.apps_runner_ryzen.ct_id
  hostname            = local.secrets.apps_runner_ryzen.hostname
  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = local.secrets.apps_runner_ryzen.disk_size

  memory_dedicated = local.secrets.apps_runner_ryzen.memory

  ip_configs = [{
    ipv4 = {
      address  = local.secrets.apps_runner_ryzen.ip
      gateway  = local.secrets.gw_ip
    }
  }]

  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
  }]

  unprivileged = true  # Mode unprivileged

  # Features pour Docker
  features = {
    nesting = true  # Requis pour Docker
  }

  # Ressources CPU (2 cœurs)
  cpu_cores = 2
}