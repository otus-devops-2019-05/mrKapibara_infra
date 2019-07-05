terraform {
  required_version = "0.11.7"
}

provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_project_metadata" "reddit-app-ssh-keys" {
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)} ${var.ssh_user}1:${file(var.public_key_path)} ${var.ssh_user}2:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance" "reddit-app-instances" {
  count        = "2"
  name         = "reddit-app-${count.index + 1}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "${var.ssh_user}"
    agent       = "false"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "reddit-app-firewall" {
  name    = "reddit-app-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}
