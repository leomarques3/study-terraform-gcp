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

resource "google_service_account" "node_sa" {
  account_id   = format("%s-node-sa", var.cluster_name)
  display_name = "GKE Security Service Account"

  depends_on = [
    google_project_service.service
  ]
}

resource "google_service_account" "bastion_sa" {
  account_id   = format("%s-bastion-sa", var.cluster_name)
  display_name = "GKE Bastion Service Account"

  depends_on = [
    google_project_service.service
  ]
}

resource "google_project_iam_member" "node_sa_role" {
  count   = length(var.service_account_iam_roles)
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.node_sa.email)
}

resource "google_container_cluster" "cluster" {
  provider                 = google-beta
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

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = format("%s/32", google_compute_instance.instance.network_interface.0.network_ip)
    }
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
}

resource "google_container_node_pool" "node_pool" {
  provider   = google-beta
  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.id
  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    oauth_scopes    = var.oauth_scopes
    service_account = google_service_account.node_sa.email

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
    email  = google_service_account.node_sa.email
    scopes = ["cloud-platform"]
  }
}