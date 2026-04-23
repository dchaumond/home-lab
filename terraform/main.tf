
resource "local_file" "ansible_inventory" {
  content = <<EOT
[pve_host]
proxmox ansible_host=${var.pve_host_ip} ansible_user=root

[storage_servers]
storage-ct ansible_host=${split("/", var.storage_ct_ip)[0]} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

[ai_servers]
ai-lab ansible_host=${split("/", var.ai_lxc_ip)[0]} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
EOT
  filename = "../ansible/inventory.ini"
}
output "debug_user" {
  value = var.pm_api_token_id
}