resource "google_compute_address" "reddit-app-ip" {
  name = "reddit-app-ip"
}

resource "google_compute_instance" "reddit-app-instances" {
  count        = "1"
  name         = "reddit-app-${count.index + 1}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config = {
      nat_ip = "${google_compute_address.reddit-app-ip.address}"
    }
  }

  connection {
    type        = "ssh"
    user        = "${var.ssh_user}"
    agent       = "false"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "../modules/app/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "../modules/app/deploy.sh"
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
