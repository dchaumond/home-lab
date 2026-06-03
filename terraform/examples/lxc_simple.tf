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
  root_password   = var.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = 10

  ip_configs = [{
    ipv4 = { address = "192.168.1.30/24"
             gw = var.gw_ip
           }
  }]
  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
    #mac_address = "BC:24:11:D0:EE:47"
  }]  


}
