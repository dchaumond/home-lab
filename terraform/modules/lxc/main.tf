##############################################################
# Module : proxmox_virtual_environment_container
# Provider: bpg/proxmox
# Description: Création d'un conteneur LXC sur Proxmox VE
#              Compatible cluster (node_name) et multi-provider (alias)
##############################################################

resource "proxmox_virtual_environment_container" "this" {

  ##########################
  # Identification
  ##########################
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = var.tags
  pool_id     = var.pool_id

  ##########################
  # Comportement général
  ##########################
  started       = var.started
  unprivileged  = var.unprivileged
  protection    = var.protection
  start_on_boot = var.start_on_boot
  template      = var.template

  ##########################
  # OS Template
  ##########################
  operating_system {
    template_file_id = var.os_template_file_id
    type             = var.os_type
  }

  ##########################
  # Initialisation
  ##########################
  initialization {
    hostname = var.hostname

    dynamic "ip_config" {
      for_each = var.ip_configs
      content {
        dynamic "ipv4" {
          for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
          content {
            address = ipv4.value.address
            gateway = lookup(ipv4.value, "gateway", null)
          }
        }
        dynamic "ipv6" {
          for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []
          content {
            address = ipv6.value.address
            gateway = lookup(ipv6.value, "gateway", null)
          }
        }
      }
    }

    dynamic "dns" {
      for_each = var.dns != null ? [var.dns] : []
      content {
        domain  = lookup(dns.value, "domain", null)
        servers = lookup(dns.value, "servers", null)
      }
    }

    user_account {
      keys     = var.ssh_public_keys
      password = var.root_password
    }
  }

  ##########################
  # CPU
  ##########################
  cpu {
    architecture = var.cpu_architecture
    cores        = var.cpu_cores
    units        = var.cpu_units
  }

  ##########################
  # Mémoire
  ##########################
  memory {
    dedicated = var.memory_dedicated
    swap      = var.memory_swap
  }

  ##########################
  # Disque racine
  ##########################
  disk {
    datastore_id = var.disk_datastore_id
    size         = var.disk_size
  }

  ##########################
  # Interfaces réseau
  ##########################
  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name        = network_interface.value.name
      bridge      = network_interface.value.bridge
      enabled     = lookup(network_interface.value, "enabled", true)
      firewall    = lookup(network_interface.value, "firewall", false)
      mac_address = lookup(network_interface.value, "mac_address", null)
      mtu         = lookup(network_interface.value, "mtu", null)
      rate_limit  = lookup(network_interface.value, "rate_limit", null)
      vlan_id     = lookup(network_interface.value, "vlan_id", null)
    }
  }

  ##########################
  # Console
  ##########################
  dynamic "console" {
    for_each = var.console != null ? [var.console] : []
    content {
      enabled   = lookup(console.value, "enabled", true)
      type      = lookup(console.value, "type", "tty")
      tty_count = lookup(console.value, "tty_count", 2)
    }
  }

  ##########################
  # Démarrage ordonné
  ##########################
  dynamic "startup" {
    for_each = var.startup != null ? [var.startup] : []
    content {
      order      = lookup(startup.value, "order", null)
      up_delay   = lookup(startup.value, "up_delay", null)
      down_delay = lookup(startup.value, "down_delay", null)
    }
  }

  ##########################
  # Features (optionnel)
  # Laisser var.features = null pour ne pas générer ce bloc
  ##########################
  dynamic "features" {
    for_each = var.features != null ? [var.features] : []
    content {
      fuse    = lookup(features.value, "fuse", null)
      keyctl  = lookup(features.value, "keyctl", null)
      nesting = lookup(features.value, "nesting", null)
      mount   = lookup(features.value, "mount", null)
    }
  }

  ##########################
  # Mount Points (optionnel)
  # Laisser var.mount_points = [] pour ne pas générer ce bloc
  ##########################
  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume        = mount_point.value.volume
      path          = mount_point.value.path
      size          = lookup(mount_point.value, "size", null)
      acl           = lookup(mount_point.value, "acl", null)
      backup        = lookup(mount_point.value, "backup", null)
      mount_options = lookup(mount_point.value, "mount_options", null)
      quota         = lookup(mount_point.value, "quota", null)
      read_only     = lookup(mount_point.value, "read_only", null)
      replicate     = lookup(mount_point.value, "replicate", null)
      shared        = lookup(mount_point.value, "shared", null)
    }
  }
}
