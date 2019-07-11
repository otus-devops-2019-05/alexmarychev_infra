resource "google_compute_global_forwarding_rule" "default" {
  name = "puma-forwarding-rule"
  target = "${google_compute_target_http_proxy.default.self_link}"
  port_range = "80"
}

resource "google_compute_instance_group" "staging_group" {
  name = "staging-instance-group"
  zone = "${var.zone}"
  instances = ["${google_compute_instance.app.*.self_link}"]
  named_port {
    name = "http"
    port = "9292"
  }
}

resource "google_compute_target_http_proxy" "default" {
  name = "puma-proxy"
  url_map = "${google_compute_url_map.default.self_link}"
}

resource "google_compute_url_map" "default" {
  name = "puma-map"
  default_service = "${google_compute_backend_service.default.self_link}"

}

resource "google_compute_backend_service" "default" {
  name = "backend-service"
  protocol = "HTTP"
  backend = [{group = "${google_compute_instance_group.staging_group.self_link}"}]
  health_checks = ["${google_compute_http_health_check.default.self_link}"]
}

resource "google_compute_http_health_check" "default" {
  name = "http-health-check"
  check_interval_sec = 10
  timeout_sec = 5
  port = "9292"
}

