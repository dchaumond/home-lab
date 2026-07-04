##############################################################
# Variables du module LXC Proxmox
##############################################################

#--------------------------
# Identification
#--------------------------
variable "node_name" {
  description = "Nom du nœud Proxmox cible (ex: pve1, pve2). En cluster, l'API est commune mais node_name cible le bon hôte."
  type        = string
}

variable "vm_id" {
  description = "ID du conteneur (laisser null pour auto-assign par Proxmox)"
  type        = number
  default     = null
}

variable "description" {
  description = "Description libre du conteneur"
  type        = string
  default     = null
}

variable "tags" {
  description = "Liste de tags associés au conteneur"
  type        = list(string)
  default     = []
}

variable "pool_id" {
  description = "ID du pool de ressources Proxmox auquel rattacher le conteneur"
  type        = string
  default     = null
}

#--------------------------
# Comportement
#--------------------------
variable "started" {
  description = "Démarrer le conteneur après création"
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Créer un conteneur non-privilégié (recommandé pour la sécurité)"
  type        = bool
  default     = true
}

variable "protection" {
  description = "Protéger le conteneur contre la suppression accidentelle"
  type        = bool
  default     = false
}

variable "start_on_boot" {
  description = "Démarrer automatiquement au démarrage du nœud Proxmox"
  type        = bool
  default     = true
}

variable "template" {
  description = "Marquer ce conteneur comme template (non démarrable directement)"
  type        = bool
  default     = false
}

#--------------------------
# OS Template
#--------------------------
variable "os_template_file_id" {
  description = "ID du fichier template OS (ex: local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst)"
  type        = string
}

variable "os_type" {
  description = "Type d'OS du conteneur"
  type        = string
  default     = "unmanaged"

  validation {
    condition = contains([
      "debian", "ubuntu", "centos", "fedora",
      "opensuse", "archlinux", "alpine", "gentoo", "unmanaged"
    ], var.os_type)
    error_message = "os_type doit être : debian, ubuntu, centos, fedora, opensuse, archlinux, alpine, gentoo ou unmanaged."
  }
}

#--------------------------
# Initialisation
#--------------------------
variable "hostname" {
  description = "Nom d'hôte du conteneur"
  type        = string
}

variable "ip_configs" {
  description = <<-EOT
    Configuration IP par interface réseau (dans l'ordre des network_interfaces).
    Utiliser address = "dhcp" pour DHCP, ou une adresse CIDR pour une IP statique.
    Exemple DHCP    : [{ ipv4 = { address = "dhcp" } }]
    Exemple statique: [{ ipv4 = { address = "192.168.1.100/24", gateway = "192.168.1.1" } }]
  EOT
  type = list(object({
    ipv4 = optional(object({
      address = string
      gateway = optional(string)
    }))
    ipv6 = optional(object({
      address = string
      gateway = optional(string)
    }))
  }))
  default = []
}

variable "dns" {
  description = <<-EOT
    Configuration DNS du conteneur.
    Exemple: { domain = "lan.example.com", servers = ["1.1.1.1", "8.8.8.8"] }
  EOT
  type = object({
    domain  = optional(string)
    servers = optional(list(string))
  })
  default = null
}

variable "ssh_public_keys" {
  description = "Clés SSH publiques autorisées pour le compte root"
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Mot de passe root du conteneur (sensible)"
  type        = string
  sensitive   = true
  default     = null
}

#--------------------------
# CPU
#--------------------------
variable "cpu_architecture" {
  description = "Architecture CPU (amd64, arm64, armhf, i386)"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64", "armhf", "i386"], var.cpu_architecture)
    error_message = "cpu_architecture doit être : amd64, arm64, armhf ou i386."
  }
}

variable "cpu_cores" {
  description = "Nombre de cœurs CPU alloués au conteneur"
  type        = number
  default     = 1
}

variable "cpu_units" {
  description = "Priorité CPU relative (100-500000, défaut Proxmox: 1024)"
  type        = number
  default     = 1024
}

#--------------------------
# Mémoire
#--------------------------
variable "memory_dedicated" {
  description = "Mémoire RAM dédiée en Mo"
  type        = number
  default     = 512
}

variable "memory_swap" {
  description = "Mémoire swap en Mo (0 pour désactiver)"
  type        = number
  default     = 512
}

#--------------------------
# Disque racine
#--------------------------
variable "disk_datastore_id" {
  description = "ID du datastore pour le disque racine (ex: local-lvm, local-zfs, local)"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Taille du disque racine en Go"
  type        = number
  default     = 8
}

#--------------------------
# Réseau
#--------------------------
variable "network_interfaces" {
  description = <<-EOT
    Liste des interfaces réseau. name et bridge sont obligatoires.
    Exemple minimal : [{ name = "eth0", bridge = "vmbr0" }]
    Exemple complet : [{
      name        = "eth0"
      bridge      = "vmbr0"
      enabled     = true
      firewall    = true
      mac_address = "BC:24:11:AA:BB:CC"
      mtu         = 1500
      rate_limit  = 100
      vlan_id     = 10
    }]
  EOT
  type = list(object({
    name        = string
    bridge      = string
    enabled     = optional(bool, true)
    firewall    = optional(bool, false)
    mac_address = optional(string)
    mtu         = optional(number)
    rate_limit  = optional(number)
    vlan_id     = optional(number)
  }))
  default = [{
    name   = "eth0"
    bridge = "vmbr0"
  }]
}

#--------------------------
# Console
#--------------------------
variable "console" {
  description = <<-EOT
    Configuration de la console série/tty. null = valeurs Proxmox par défaut.
    Exemple: { enabled = true, type = "tty", tty_count = 2 }
    type peut être : tty, console, socket
  EOT
  type = object({
    enabled   = optional(bool, true)
    type      = optional(string, "tty")
    tty_count = optional(number, 2)
  })
  default = null
}

#--------------------------
# Démarrage ordonné
#--------------------------
variable "startup" {
  description = <<-EOT
    Ordre et délais de démarrage/arrêt du conteneur.
    null = pas de configuration d'ordre.
    Exemple: { order = 2, up_delay = 10, down_delay = 5 }
  EOT
  type = object({
    order      = optional(number)
    up_delay   = optional(number)
    down_delay = optional(number)
  })
  default = null
}

#--------------------------
# Features (optionnel)
#--------------------------
variable "features" {
  description = <<-EOT
    Fonctionnalités avancées du conteneur LXC.
    null = bloc features absent (comportement Proxmox par défaut).

    - fuse    : Support FUSE (ex: sshfs dans le conteneur)
    - keyctl  : Support keyctl (nécessaire pour certaines distros comme Ubuntu)
    - nesting : Virtualisation imbriquée — indispensable pour Docker-in-LXC
    - mount   : Systèmes de fichiers montables depuis le conteneur (ex: ["nfs", "cifs"])

    Note: nesting=true et keyctl=true nécessitent généralement unprivileged=true
    avec les droits adéquats côté Proxmox, ou unprivileged=false.

    Exemple Docker : { nesting = true, keyctl  = true }
    Exemple NFS    : { mount   = ["nfs", "cifs"] }
  EOT
  type = object({
    fuse    = optional(bool)
    keyctl  = optional(bool)
    nesting = optional(bool)
    mount   = optional(list(string))
  })
  default = null
}

#--------------------------
# Mount Points (optionnel)
#--------------------------
variable "mount_points" {
  description = <<-EOT
    Points de montage supplémentaires (bind mounts ou volumes dédiés).
    [] = aucun mount point (par défaut).

    volume et path sont obligatoires.

    Bind mount (répertoire hôte → conteneur):
      { volume = "/mnt/nas/data", path = "/data" }

    Volume dédié sur datastore:
      { volume = "local-lvm", path = "/opt/app", size = 20, backup = true }

    Options disponibles:
    - size          : Taille en Go (pour les volumes sur datastore)
    - acl           : Activer les ACL POSIX
    - backup        : Inclure dans les sauvegardes Proxmox
    - mount_options : Options de montage supplémentaires (ex: ["noatime"])
    - quota         : Activer les quotas utilisateur/groupe
    - read_only     : Monter en lecture seule
    - replicate     : Inclure dans la réplication de cluster
    - shared        : Marquer comme stockage partagé entre nœuds
  EOT
  type = list(object({
    volume        = string
    path          = string
    size          = optional(number)
    acl           = optional(bool)
    backup        = optional(bool)
    mount_options = optional(list(string))
    quota         = optional(bool)
    read_only     = optional(bool)
    replicate     = optional(bool)
    shared        = optional(bool)
  }))
  default = []
}
