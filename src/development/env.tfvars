##### Project #####
region = "northamerica-northeast1"
zone = "northamerica-northeast1-c"
project_services = [
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
image_repository_name = "health-images-repo"

##### Network #####
network_name = "health-vpc-network-dev"
subnetwork_name = "health-vpc-subnetwork-dev"
ip_cidr_subnetwork = "10.2.0.0/16"
ip_services_name = "health-service-range-dev"
ip_cidr_services = "10.100.0.0/20"
ip_pods_name = "health-pod-range-dev"
ip_cidr_pods = "10.96.0.0/14"
ipv4_cidr_block = "172.16.0.16/28"
rule_name = "allow-inbound-nginx"
router_name = "health-router-dev"
nat_name = "health-nat-ip-dev"
nat_allocate_option = "AUTO_ONLY"
nat_source_range = "ALL_SUBNETWORKS_ALL_IP_RANGES"

##### Cluster #####
cluster_name = "health-cluster-dev"
node_locations = [
  "northamerica-northeast1-c"
]
node_pool_name = "health-node-pool"
node_count = 3

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