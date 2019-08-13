resource "google_compute_instance" "db" {
  name         = "reddit-db"
  machine_type = "g1-small"
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
  }

  metadata {
    ssh-keys = "alexmar:${file(var.public_key_path)}"
  }

//  connection {
//    type  = "ssh"
//    user  = "alexmar"
//    private_key = "${file(var.private_key_path)}"
//    host  = "${google_compute_instance.db.network_interface.0.access_config.0.nat_ip}"
//  }
//
//  provisioner "remote-exec" {
//      inline = [
//        "sudo sed 's/bindIp: 127.0.0.1/bindIp: ${google_compute_instance.db.network_interface.0.network_ip}/' /etc/mongod.conf -i",
//        "sudo systemctl restart mongod",
//      ]
//  }
}

# Правило firewall
resource "google_compute_firewall" "firewall_mongo" {
  name    = "allow-mongo-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  target_tags = ["reddit-db"]
  source_tags = ["reddit-app"]
}

