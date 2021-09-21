##### Project #####
variable "project_id" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = null
}

variable "zone" {
  type    = string
  default = null
}

variable "project_services" {
  type = list(string)
  default = null
}

variable "service_account_iam_roles" {
  type = list(string)
  default = null
}

##### Repository #####
variable "image_repository_name" {
  type    = string
  default = null
}

##### Network #####
variable "network_name" {
  type    = string
  default = null
}

variable "subnetwork_name" {
  type    = string
  default = null
}

variable "ip_cidr_subnetwork" {
  type    = string
  default = null
}

variable "ip_services_name" {
  type    = string
  default = null
}

variable "ip_cidr_services" {
  type    = string
  default = null
}

variable "ip_pods_name" {
  type    = string
  default = null
}

variable "ip_cidr_pods" {
  type    = string
  default = null
}

variable "ipv4_cidr_block" {
  type    = string
  default = null
}

variable "nginx_rule_name" {
  type    = string
  default = null
}

variable "ssh_rule_name" {
  type    = string
  default = null
}

variable "router_name" {
  type    = string
  default = null
}

variable "nat_name" {
  type    = string
  default = null
}

variable "nat_allocate_option" {
  type    = string
  default = null
}

variable "nat_source_range" {
  type    = string
  default = null
}

variable "ip_source_range" {
  type    = list(string)
  default = null
}

##### Cluster #####
variable "cluster_name" {
  type    = string
  default = null
}

variable "node_locations" {
  type    = list(string)
  default = null
}

variable "logging_service" {
  type    = string
  default = null
}

variable "monitoring_service" {
  type    = string
  default = null
}

variable "node_pool_name" {
  type    = string
  default = null
}

variable "node_count" {
  type    = number
  default = null
}

##### Compute #####
variable "machine_type" {
  type    = string
  default = null
}

variable "oauth_scopes" {
  type    = list(string)
  default = null
}