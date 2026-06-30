module "home_automation_ryzen" {
  source = "../../modules/lxc"

  node_name           = "pve-ryzen"
  vm_id               = local.secrets.home_automation_ryzen.ct_id
  hostname            = local.secrets.home_automation_ryzen.hostname
  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = local.secrets.home_automation_ryzen.disk_size

  memory_dedicated = local.secrets.home_automation_ryzen.memory

  ip_configs = [{
    ipv4 = {
      address  = local.secrets.home_automation_ryzen.ip
      gateway  = local.secrets.gw_ip
    }
  }]

  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
    mac_address = local.secrets.home_automation_ryzen.mac_address
  }]

  unprivileged = true

  features = {
    nesting = true
    keyctl  = true
  }

  cpu_cores = 2
}
