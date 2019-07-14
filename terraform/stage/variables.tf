variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable public_key_path {
  description = "Path to .pub key file"
}

variable app_disk_image {
  description = "Disc image"
}

variable zone {
  description = "Zone name"
  default     = "europe-west1-c"
}

variable private_key_path {
  description = "Path to privat part"
}

variable "machine_type" {
  description = "Machine-type. default: 'f1-micro'"
  default     = "f1-micro"
}

variable "ssh_user" {
  description = "User for ssh connection"
}

variable "db_disk_image" {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

