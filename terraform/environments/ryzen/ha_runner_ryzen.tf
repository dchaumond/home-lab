module "ha_runner_ryzen" {
  source = "../../modules/lxc"

  node_name           = "pve-ryzen"
  vm_id               = local.secrets.ha_runner_ryzen.ct_id  # ID depuis .env.json
  hostname            = local.secrets.ha_runner_ryzen.hostname  # Hostname depuis .env.json
  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = local.secrets.ha_runner_ryzen.disk_size  # Taille du disque depuis .env.json

  memory_dedicated = local.secrets.ha_runner_ryzen.memory  # Mémoire dédiée depuis .env.json

  ip_configs = [{
    ipv4 = {
      address = local.secrets.ha_runner_ryzen.ip  # IP depuis .env.json
      gateway = local.secrets.gw_ip
    }
  }]

  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
  }]

  unprivileged = false  # Mode privileged activé
}