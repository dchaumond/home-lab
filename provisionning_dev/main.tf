resource "local_file" "ansible_inventory" {
  content = <<EOT
[pve_host]
proxmox ansible_host=${var.pve_host_ip} ansible_user=root

[dev_servers]
dev_station ansible_host=${split("/", var.dev_lxc_ip)[0]} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
EOT
  filename = "./inventory.ini"
}
