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
  network_tier          = "STANDARD"
  target                = "${google_compute_target_pool.reddit-app-pool.self_link}"
}

resource "google_compute_http_health_check" "reddit-app-health-check" {
  name               = "reddit-app-health-check"
  check_interval_sec = 1
  timeout_sec        = 1
  port               = "9292"
}
