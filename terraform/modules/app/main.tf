resource "google_compute_address" "reddit-app-ip" {
  name = "reddit-app-ip"
  network_tier          = "STANDARD"
}

resource "google_compute_instance" "reddit-app-instances" {
  count        = "2"
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

    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "${var.ssh_user}"
    agent       = "false"
    private_key = "${file(var.private_key_path)}"
  }

  # provisioner "file" {
  #   source      = "../modules/app/puma.service"
  #   destination = "/tmp/puma.service"
  # }

  # provisioner "remote-exec" {
  #   script = "../modules/app/deploy.sh"
  # }
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

resource "google_compute_target_pool" "reddit-app-pool" {
  name = "reddit-app-pool"
  instances = [
    "${google_compute_instance.reddit-app-instances.*.self_link}",
  ]
  health_checks = [
    "${google_compute_http_health_check.reddit-app-health-check.self_link}",
  ]
  region = "${var.region}"
}

resource "google_compute_forwarding_rule" "reddit-app-balancer" {
  name                  = "reddit-app-balancer"
  region                = "${var.region}"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "9292"
  ip_address = "${google_compute_address.reddit-app-ip.self_link}"
  network_tier          = "STANDARD"
  target                = "${google_compute_target_pool.reddit-app-pool.self_link}"
}

resource "google_compute_http_health_check" "reddit-app-health-check" {
  name               = "reddit-app-health-check"
  check_interval_sec = 1
  timeout_sec        = 1
  port               = "9292"
}
