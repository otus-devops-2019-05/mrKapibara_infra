variable "ssh_user" {
  description = "User for ssh connection"
}

variable public_key_path {
  description = "Path to .pub key file"
}

variable "source_ranges" {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}
