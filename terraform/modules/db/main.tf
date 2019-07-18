resource "google_compute_address" "reddit-db-ip" {
  name         = "reddit-db-ip"
  address_type = "INTERNAL"
}

data "template_file" "init" {
  template = "${file("../modules/db/mongod.conf.tpl")}"

  vars = {
    reddit-db-ip = "${google_compute_address.reddit-db-ip.address}"
  }
}

resource "google_compute_instance" "reddit-db-instances" {
  count        = "1"
  name         = "reddit-db-${count.index + 1}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["reddit-db"]

  boot_disk {
    initialize_params {
      image = "${var.db_disk_image}"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
    network_ip    = "${google_compute_address.reddit-db-ip.address}"
  }

  connection {
    type        = "ssh"
    user        = "${var.ssh_user}"
    agent       = "false"
    private_key = "${file(var.private_key_path)}"
  }

  # provisioner "file" {
  #   content     = "${data.template_file.init.rendered}"
  #   destination = "/tmp/mongod.conf"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo mv -f /tmp/mongod.conf /etc/mongod.conf",
  #     "sudo systemctl restart mongod.service",
  # #   ]
  # }
}

resource "google_compute_firewall" "reddit-db-firewall" {
  name    = "allow-mongo-default"
  network = "default"

  allow = {
    protocol = "tcp"
    ports    = ["27017"]
  }

  target_tags = ["reddit-db"]
  source_tags = ["reddit-app"]
}
