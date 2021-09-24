resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.service
  ]
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name                     = var.subnetwork_name
  ip_cidr_range            = var.ip_cidr_subnetwork
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.ip_services_name
    ip_cidr_range = var.ip_cidr_services
  }

  secondary_ip_range {
    range_name    = var.ip_pods_name
    ip_cidr_range = var.ip_cidr_pods
  }
}

resource "google_compute_firewall" "allow-inbound-nginx" {
  name    = var.nginx_rule_name
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]
  }
}

resource "google_compute_firewall" "allow-inbound-ssh" {
  name          = var.ssh_rule_name
  network       = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_address" "address" {
  name    = format("%s-nat-ip", var.cluster_name)
  region  = var.region

  depends_on = [
    google_project_service.service
  ]
}

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ips                            = [google_compute_address.address.self_link]
  nat_ip_allocate_option             = var.nat_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.nat_source_range

  subnetwork {
    name                     = google_compute_subnetwork.vpc_subnetwork.id
    source_ip_ranges_to_nat  = var.ip_source_range
    secondary_ip_range_names = [var.ip_pods_name, var.ip_services_name]
  }
}

resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta
  name          = format("%s-priv-ip", var.cluster_name)
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.vpc_network.name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}