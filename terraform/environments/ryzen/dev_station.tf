module "dev_station_ryzen" {
  source = "../../modules/lxc"

  node_name           = local.secrets.pve_node_ryzen
  vm_id               = local.secrets.dev_station_ryzen.ct_id
  hostname            = local.secrets.dev_station_ryzen.hostname
  tags                = ["dev", "ryzen"]

  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = local.secrets.dev_station_ryzen.disk_size

  ip_configs = [{
    ipv4 = {
      address = local.secrets.dev_station_ryzen.ip
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

  cpu_cores       = local.secrets.dev_station_ryzen.cpu_cores
  memory_dedicated = local.secrets.dev_station_ryzen.memory
  memory_swap      = local.secrets.dev_station_ryzen.memory_swap
}
