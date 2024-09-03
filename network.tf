data "google_compute_network" "existing_network" {
  name = var.network_name
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_ip_range
  region        = var.region
  network       = data.google_compute_network.existing_network.self_link
}

resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = data.google_compute_network.existing_network.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
