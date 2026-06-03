module "lxc_storage" {
  source = "../../modules/lxc"
  providers = {
    proxmox = proxmox
  }

  node_name           = local.secrets.pve_node_ryzen
  vm_id               = local.secrets.lxc_storage.ct_id
  hostname            = local.secrets.lxc_storage.hostname
  tags                = ["storage", "samba", "minio"]

  os_template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  os_type             = "debian"

  ssh_public_keys = [local.secrets.ssh_key_homelab]
  root_password   = local.secrets.root_password

  disk_datastore_id = "local-lvm"
  disk_size         = 10

  ip_configs = [{
    ipv4 = { address = local.secrets.lxc_storage.ip
             gw = local.secrets.gw_ip
           }
  }]
  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
    #mac_address = "BC:24:11:D0:EE:47"
  }]  

  unprivileged = true

  features = {
    nesting = true
    keyctl  = true
  }

  mount_points = local.secrets.lxc_storage.mount_points

}
