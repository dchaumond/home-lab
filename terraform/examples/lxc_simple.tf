module "lxc_simple" {
  source = "./modules/lxc"
  providers = {
    proxmox = proxmox.pve-ryzen
  }

  node_name           = var.pve_node_ryzen
  vm_id               = 300
  hostname            = "lxc-simple"
  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [var.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = local.secrets.disk_datastore_id
  disk_size         = 10

  ip_configs = [{
    ipv4 = { address = "${local.secrets.apps_runner_ip}/24"
             gw = local.secrets.gateway_ip
           }
  }]
  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
    #mac_address = "BC:24:11:D0:EE:47"
  }]  


}
