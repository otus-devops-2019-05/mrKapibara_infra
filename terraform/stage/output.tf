output "app-external-ip" {
  value = "${module.app.reddit-app-external-ip}"
}

output "db-external-ip" {
  value = "${module.app.reddit-db-external-ip}"
}
