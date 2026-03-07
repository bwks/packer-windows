variable "iso_url" {
  type        = string
  description = "Path or URL to Windows Server 2022 ISO"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum for the Windows Server 2022 ISO (e.g. sha256:abc123...)"
}


variable "virtio_iso_path" {
  type        = string
  description = "Path to the VirtIO drivers ISO"
  default     = ""
}

variable "winrm_username" {
  type        = string
  default     = "Administrator"
  description = "WinRM username for Packer communicator"
}

variable "winrm_password" {
  type        = string
  sensitive   = true
  description = "WinRM/Administrator password"
}

variable "vm_cpus" {
  type    = number
  default = 4
}

variable "vm_memory" {
  type    = number
  default = 8192
}

variable "disk_size" {
  type        = string
  default     = "61440M"
  description = "Disk size with unit suffix (e.g. 61440M)"
}

variable "headless" {
  type    = bool
  default = true
}

variable "output_directory" {
  type    = string
  default = "output-win2022"
}

variable "vm_name" {
  type    = string
  default = "win2022-cloudbase"
}
