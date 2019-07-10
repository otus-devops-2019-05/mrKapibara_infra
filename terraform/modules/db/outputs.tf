
output "reddit-db-external-ip" {
  value = "${google_compute_instance.reddit-db-instances.*.network_interface.0.access_config.0.nat_ip}"
}
