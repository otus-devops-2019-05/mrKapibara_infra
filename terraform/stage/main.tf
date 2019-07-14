provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "vpc" {
  source          = "../modules/vpc"
  ssh_user        = "${var.ssh_user}"
  public_key_path = "${var.public_key_path}"
}

module "db" {
  source           = "../modules/db"
  private_key_path = "${var.private_key_path}"
  zone             = "${var.zone}"
  db_disk_image    = "${var.db_disk_image}"
  ssh_user         = "${var.ssh_user}"
}

module "app" {
  source           = "../modules/app"
  private_key_path = "${var.private_key_path}"
  zone             = "${var.zone}"
  app_disk_image   = "${var.app_disk_image}"
  ssh_user         = "${var.ssh_user}"
  region = "${var.region}"
}
