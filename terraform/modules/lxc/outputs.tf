##############################################################
# Outputs du module LXC Proxmox
##############################################################

output "id" {
  description = "ID Terraform de la ressource conteneur"
  value       = proxmox_virtual_environment_container.this.id
}

output "vm_id" {
  description = "VMID Proxmox du conteneur"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "node_name" {
  description = "Nœud Proxmox hébergeant le conteneur"
  value       = proxmox_virtual_environment_container.this.node_name
}

output "network_interfaces" {
  description = "Interfaces réseau du conteneur (nom, bridge, mac…)"
  value       = proxmox_virtual_environment_container.this.network_interface
}

output "started" {
  description = "Etat de démarrage du conteneur"
  value       = proxmox_virtual_environment_container.this.started
}
