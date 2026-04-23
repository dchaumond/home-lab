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

# --- CONTAINER STORAGE (SMB) ---
variable "dev_lxc_id" {
  type    = number
}

variable "dev_lxc_hostname" {
  type    = string
}

variable "dev_lxc_password" {
  type      = string
  sensitive = true
}

variable "dev_lxc_memory" {
  type    = number
}

variable "dev_lxc_root_size" {
  type    = number
}

variable "dev_lxc_ip" {
  type    = string
}

variable "dev_lxc_mac" {
  type    = string
}