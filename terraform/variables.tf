# --- ACCÈS API ---
variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

# --- INFRA GLOBALE ---
variable "pve_node" {
  type = string
}

variable "pve_host_ip" {
  type = string
}

variable "gw_ip" {
  type = string
}

variable "pve_template_storage" {
  type = string
}

variable "pve_root_password" {
  type = string
}

variable "ssh_key_homelab" {
  type        = string
}

# --- CONTAINER STORAGE (SMB) ---
variable "storage_ct_id" {
  type = number
}

variable "storage_ct_hostname" {
  type = string
}

variable "storage_ct_ip" {
  type = string
}

variable "storage_mount_samba_host" {
  type = string
}

variable "storage_mount_samba_dest" {
  type = string
}

variable "storage_mount_minio_host" {
  type = string
}

variable "storage_mount_minio_dest" {
  type = string
}

variable "storage_root_size" {
  type = number
}

variable "storage_ct_root_password" {
  type = string
}

variable "storage_ct_mac_address" {
  type = string
}

# --- CONTAINER AI ---

variable "ai_lxc_id" {
  type        = number
}

variable "ai_lxc_hostname" {
  type        = string
}

variable "ai_lxc_ip" {
  type        = string
}

variable "ai_lxc_mac" {
  type        = string
}

variable "ai_lxc_root_size" {
  type = number
}

variable "ai_lxc_password" {
  type        = string
  sensitive   = true
}

variable "ai_lxc_memory" {
  type = number
}

variable "ai_lxc_swap" {
  type = number
}
