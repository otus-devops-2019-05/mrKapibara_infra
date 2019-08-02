output "app-external-ip" {
  value = "${module.app.reddit-app-external-ip}"
}

output "db-external-ip" {
  value = "${module.db.reddit-db-external-ip}"
}

output "reddit-app-lb-ip" {
  value = "${module.app.reddit-app-lb-ip}"
}
