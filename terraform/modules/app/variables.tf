variable "machine_type" {
  description = "Machine-type. default: 'f1-micro'"
  default     = "f1-micro"
}

variable zone {
  description = "Zone name"
  default     = "europe-west1-c"
}

variable app_disk_image {
  description = "Disc image"
  default = "reddit-app-base"
}

variable "ssh_user" {
  description = "User for ssh connection"
}

variable private_key_path {
  description = "Path to privat part"
}
