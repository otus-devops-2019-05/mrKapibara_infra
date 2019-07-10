variable "machine_type" {
  description = "Machine-type. default: 'f1-micro'"
  default     = "f1-micro"
}

variable "db_disk_image" {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable zone {
  description = "Zone name"
  default     = "europe-west1-c"
}

variable "ssh_user" {
  description = "User for ssh connection"
}

variable private_key_path {
  description = "Path to privat part"
}
