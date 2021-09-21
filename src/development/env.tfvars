##### Project #####
region = "us-central1"
zone = "us-central1-b"
project_services = [
  "cloudresourcemanager.googleapis.com",
  "compute.googleapis.com",
  "container.googleapis.com",
  "artifactregistry.googleapis.com"
]
service_account_iam_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/monitoring.viewer",
  "roles/compute.serviceAgent",
  "roles/container.serviceAgent",
  "roles/artifactregistry.admin"
]

##### Repository #####
image_repository_name = "study-image-repo"

##### Network #####
network_name = "study-vpc-network"
subnetwork_name = "study-vpc-subnetwork"
ip_cidr_subnetwork = "10.2.0.0/16"
ip_services_name = "study-service-range"
ip_cidr_services = "10.100.0.0/20"
ip_pods_name = "study-pod-range"
ip_cidr_pods = "10.96.0.0/14"
ipv4_cidr_block = "172.16.0.16/28"
nginx_rule_name = "allow-inbound-nginx"
ssh_rule_name = "allow-inbound-ssh"
router_name = "study-router"
nat_name = "study-nat-ip"
nat_allocate_option = "MANUAL_ONLY"
nat_source_range = "LIST_OF_SUBNETWORKS"
ip_source_range = [
  "PRIMARY_IP_RANGE",
  "LIST_OF_SECONDARY_IP_RANGES"
]

##### Cluster #####
cluster_name = "study-cluster"
node_locations = [
  "us-central1-b"
]
logging_service = "logging.googleapis.com/kubernetes"
monitoring_service = "monitoring.googleapis.com/kubernetes"
node_pool_name = "study-node-pool"
node_count = 1

##### Compute #####
machine_type = "g1-small"
oauth_scopes = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/devstorage.read_only",
  "https://www.googleapis.com/auth/logging.write",
  "https://www.googleapis.com/auth/monitoring",
  "https://www.googleapis.com/auth/servicecontrol",
  "https://www.googleapis.com/auth/service.management.readonly",
  "https://www.googleapis.com/auth/trace.append"
]