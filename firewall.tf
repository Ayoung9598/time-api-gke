# Note: GKE LoadBalancer services automatically create firewall rules.
# These custom firewall rules may be redundant but are kept for:
# - Additional security layers
# - Future use with other resources
# - Explicit documentation of allowed traffic
#
# GKE nodes don't automatically get target_tags, so these rules apply to
# resources that explicitly use these tags, not to GKE nodes directly.

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = data.google_compute_network.existing_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = data.google_compute_network.existing_network.self_link
  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]
}
