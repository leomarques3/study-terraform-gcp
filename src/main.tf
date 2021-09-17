provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "service" {
  count   = length(var.project_services)
  service = element(var.project_services, count.index)
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "image_repository" {
  provider = google-beta
  location = var.region
  repository_id = var.image_repository_name
  format = "DOCKER"

  depends_on = [
    google_project_service.service
  ]
}
#
resource "google_service_account" "service_account" {
  account_id   = format("%s-node-sa", var.cluster_name)
  display_name = "GKE Security Service Account"

  depends_on = [
    google_project_service.service
  ]
}

resource "google_project_iam_member" "service_account_roles" {
  count   = length(var.service_account_iam_roles)
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.service_account.email)

  depends_on = [
    google_service_account.service_account
  ]
}

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

  depends_on = [
    google_compute_network.vpc_network
  ]
}

resource "google_container_cluster" "cluster" {
  name                     = var.cluster_name
  location                 = var.region
  initial_node_count       = 1
  remove_default_node_pool = true
  network                  = google_compute_network.vpc_network.id
  subnetwork               = google_compute_subnetwork.vpc_subnetwork.id
  node_locations           = var.node_locations

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_pods_name
    services_secondary_range_name = var.ip_services_name
  }

  depends_on = [
    google_compute_subnetwork.vpc_subnetwork
  ]
}

resource "google_container_node_pool" "node_pool" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.id
  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    oauth_scopes    = var.oauth_scopes
    service_account = google_service_account.service_account.email
  }

  depends_on = [
    google_container_cluster.cluster
  ]
}

resource "google_compute_firewall" "allow-inbound-nginx" {
  name    = var.rule_name
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]
  }

  depends_on = [
    google_container_cluster.cluster
  ]
}

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc_network.id

  depends_on = [
    google_container_cluster.cluster
  ]
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = var.nat_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.nat_source_range

  depends_on = [
    google_compute_router.router
  ]
}