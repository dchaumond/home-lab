##############################################################
# Exemple d'utilisation du module LXC
# Fichier à placer à la racine de votre projet Terraform
##############################################################

#-------------------------------------------------------------
# Exemple 1 — Conteneur minimal (DHCP, pas de features)
#-------------------------------------------------------------
module "lxc_simple" {
  source = "./modules/lxc"

  node_name           = "pve"
  hostname            = "ct-simple"
  os_template_file_id = "local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
  os_type             = "debian"

  ip_configs = [{
    ipv4 = { address = "dhcp" }
  }]
}

#-------------------------------------------------------------
# Exemple 2 — Conteneur Docker (nesting activé via features)
#-------------------------------------------------------------
module "lxc_docker" {
  source = "./modules/lxc"

  node_name           = "pve"
  hostname            = "ct-docker"
  os_template_file_id = "local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
  os_type             = "debian"

  vm_id        = 200
  description  = "Conteneur Docker"
  tags         = ["docker", "prod"]
  unprivileged = true
  start_on_boot = true

  cpu_cores        = 4
  memory_dedicated = 2048
  memory_swap      = 1024
  disk_size        = 20

  ip_configs = [{
    ipv4 = {
      address = "192.168.1.200/24"
      gateway = "192.168.1.1"
    }
  }]

  dns = {
    servers = ["1.1.1.1", "8.8.8.8"]
  }

  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
    vlan_id = 10
  }]

  ssh_public_keys = [
    "ssh-ed25519 AAAAC3Nza... user@host"
  ]

  # Features : nesting pour Docker-in-LXC
  features = {
    nesting = true
    keyctl  = true
  }

  startup = {
    order    = 1
    up_delay = 15
  }
}

#-------------------------------------------------------------
# Exemple 3 — Conteneur avec mount points (NFS + bind)
#-------------------------------------------------------------
module "lxc_storage" {
  source = "./modules/lxc"

  node_name           = "pve"
  hostname            = "ct-storage"
  os_template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  os_type             = "ubuntu"

  vm_id            = 201
  cpu_cores        = 2
  memory_dedicated = 1024
  disk_size        = 10

  ip_configs = [{
    ipv4 = { address = "dhcp" }
  }]

  # Features NFS
  features = {
    nesting = false
    mount   = ["nfs", "cifs"]
  }

  # Mount points : un volume LVM et un bind mount
  mount_points = [
    {
      volume  = "local-lvm"
      path    = "/opt/data"
      size    = 50
      backup  = true
    },
    {
      volume    = "/mnt/nas/share"
      path      = "/mnt/nas"
      read_only = false
      shared    = true
    }
  ]
}

##############################################################
# Exemples d'utilisation du module LXC
# À adapter dans votre main.tf racine
##############################################################

###############################################################
# CAS 1 — CLUSTER PROXMOX
# Un seul provider, plusieurs nœuds via node_name
###############################################################

# racine/versions.tf
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://pve1.lan:8006"   # n'importe quel nœud du cluster
  username = "terraform@pve"
  password = var.proxmox_password
  insecure = true
}

# Conteneur minimal sur pve1 (DHCP)
module "lxc_pve1_simple" {
  source = "./modules/lxc"

  node_name           = "pve1"
  hostname            = "ct-simple"
  os_template_file_id = "local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
  os_type             = "debian"

  ip_configs = [{ ipv4 = { address = "dhcp" } }]
}

# Conteneur Docker sur pve2 (features nesting)
module "lxc_pve2_docker" {
  source = "./modules/lxc"

  node_name           = "pve2"           # ← autre nœud, même provider
  hostname            = "ct-docker"
  os_template_file_id = "local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
  os_type             = "debian"

  vm_id         = 200
  description   = "Hôte Docker"
  tags          = ["docker", "prod"]
  start_on_boot = true

  cpu_cores        = 4
  memory_dedicated = 2048
  disk_size        = 30
  disk_datastore_id = "local-zfs"

  ip_configs = [{
    ipv4 = { address = "192.168.1.200/24", gateway = "192.168.1.1" }
  }]

  dns = { servers = ["1.1.1.1", "8.8.8.8"] }

  network_interfaces = [{
    name    = "eth0"
    bridge  = "vmbr0"
    vlan_id = 10
    firewall = true
  }]

  ssh_public_keys = ["ssh-ed25519 AAAAC3Nza... user@host"]

  features = {
    nesting = true
    keyctl  = true
  }

  startup = { order = 1, up_delay = 15 }
}


###############################################################
# CAS 2 — NŒUDS STANDALONE (pas de cluster)
# Un provider par nœud avec alias
###############################################################

provider "proxmox" {
  alias    = "pve_prod"
  endpoint = "https://192.168.1.10:8006"
  username = "terraform@pve"
  password = var.proxmox_password_prod
  insecure = true
}

provider "proxmox" {
  alias    = "pve_dev"
  endpoint = "https://192.168.1.11:8006"
  username = "terraform@pve"
  password = var.proxmox_password_dev
  insecure = true
}

# Conteneur sur le nœud PROD — passage de l'alias via providers = {}
module "lxc_prod" {
  source = "./modules/lxc"

  providers = {
    proxmox = proxmox.pve_prod   # ← injection de l'alias
  }

  node_name           = "pve-prod"
  hostname            = "ct-prod-app"
  os_template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  os_type             = "ubuntu"

  cpu_cores        = 2
  memory_dedicated = 1024
  disk_size        = 20

  ip_configs = [{
    ipv4 = { address = "10.0.1.50/24", gateway = "10.0.1.1" }
  }]

  mount_points = [
    {
      volume  = "local-lvm"
      path    = "/opt/app"
      size    = 20
      backup  = true
    }
  ]
}

# Conteneur sur le nœud DEV — autre alias
module "lxc_dev" {
  source = "./modules/lxc"

  providers = {
    proxmox = proxmox.pve_dev   # ← alias différent
  }

  node_name           = "pve-dev"
  hostname            = "ct-dev-app"
  os_template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  os_type             = "ubuntu"

  cpu_cores        = 1
  memory_dedicated = 512
  disk_size        = 10

  ip_configs = [{ ipv4 = { address = "dhcp" } }]

  # Pas de features ni mount_points → blocs absents du plan
}
