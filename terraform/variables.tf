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

variable "pve_template_storage" {
  type = string
}

variable "pve_root_password" {
  type = string
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

variable "storage_ct_gw" {
  type = string
}

variable "storage_mount_host" {
  type = string
}

variable "storage_mount_dest" {
  type = string
}

variable "storage_root_size" {
  type = number
}

variable "storage_ct_root_password" {
  type = string
}
