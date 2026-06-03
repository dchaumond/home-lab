module "apps_runner_nuc" {
  source = "../../modules/lxc"
  providers = {
    proxmox = proxmox.nuc
  }

  node_name           = local.secrets.pve_node_nuc
  vm_id               = local.secrets.apps_runner_nuc.ct_id
  hostname            = local.secrets.apps_runner_nuc.hostname
  tags                = ["apps", "docker", "runner"]

  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = 20

  ip_configs = [{
    ipv4 = {
      address = local.secrets.apps_runner_nuc.ip
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
    keyctl  = true
  }

  cpu_cores = 2
  memory_dedicated = 2048
}