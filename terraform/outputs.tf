output "reddit-app-external-ip" {
  value = "${google_compute_instance.reddit-app-instances.*.network_interface.0.access_config.0.nat_ip}"
}

output "reddit-app-balancer-ip" {
  value = "${google_compute_forwarding_rule.reddit-app-balancer.ip_address}"
}
