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
  count              = length(var.project_services)
  service            = element(var.project_services, count.index)
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "image_repository" {
  provider      = google-beta
  location      = var.region
  repository_id = var.image_repository_name
  format        = "DOCKER"

  depends_on = [
    google_project_service.service
  ]
}
#
resource "google_service_account" "service_account_node" {
  account_id   = format("%s-node-sa", var.cluster_name)
  display_name = "GKE Security Service Account"

  depends_on = [
    google_project_service.service
  ]
}

resource "google_service_account" "service_account_bastion" {
  account_id   = format("%s-bastion-sa", var.cluster_name)
  display_name = "GKE Bastion Service Account"

  depends_on = [
    google_project_service.service
  ]
}

resource "google_project_iam_member" "service_account_roles" {
  count   = length(var.service_account_iam_roles)
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.service_account_node.email)

  depends_on = [
    google_service_account.service_account_node
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
  provider                 = "google-beta"
  name                     = var.cluster_name
  location                 = var.region
  initial_node_count       = 1
  remove_default_node_pool = true
  network                  = google_compute_network.vpc_network.id
  subnetwork               = google_compute_subnetwork.vpc_subnetwork.id
  node_locations           = var.node_locations
  logging_service          = var.logging_service
  monitoring_service       = var.monitoring_service

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  workload_identity_config {
    identity_namespace = format("%s.svc.id.goog", var.project_id)
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network_policy {
    enabled = true
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_pods_name
    services_secondary_range_name = var.ip_services_name
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_compute_subnetwork.vpc_subnetwork
  ]
}

resource "google_container_node_pool" "node_pool" {
  provider   = "google-beta"
  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.id
  node_count = var.node_count

  management {
    auto_repair  = true
    auto_upgrade = false
  }

  node_config {
    machine_type    = var.machine_type
    oauth_scopes    = var.oauth_scopes
    service_account = google_service_account.service_account_node.email

    labels = {
      cluster = var.cluster_name
    }

    metadata = {
      google-compute-enable-virtio-rng = true
      disable-legacy-endpoints         = true
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }

  depends_on = [
    google_container_cluster.cluster
  ]
}

resource "google_compute_firewall" "allow-inbound-nginx" {
  name    = var.nginx_rule_name
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]
  }

  depends_on = [
    google_container_cluster.cluster
  ]
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
    google_project_service.service,
  ]
}

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }

  depends_on = [
    google_container_cluster.cluster
  ]
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

  depends_on = [
    google_compute_router.router,
    google_compute_address.address
  ]
}

resource "google_compute_instance" "instance" {
  name                      = format("%s-bastion", var.cluster_name)
  machine_type              = "g1-small"
  zone                      = var.zone
  allow_stopping_for_update = true

  metadata_startup_script = <<-EOF
  sudo apt-get update -y
  sudo apt-get install -y tinyproxy
  EOF

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnetwork.name

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email = google_service_account.service_account_bastion.email
    scopes = ["cloud-platform"]
  }
}