output "cluster_name" {
  description = "Convenience output to obtain the GKE Cluster name"
  value       = google_container_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = google_container_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)"
  value       = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
}

output "get_credentials" {
  description = "gcloud get-credentials command"
  value       = format("gcloud container clusters get-credentials --project %s --region %s --internal-ip %s", var.project_id, var.region, var.cluster_name)
}
output "bastion_ssh" {
  description = "gcloud compute ssh to the bastion host command"
  value       = format("gcloud compute ssh %s --project %s --zone %s -- -tt -L8888:127.0.0.1:8888", google_compute_instance.instance.name, var.project_id, google_compute_instance.instance.zone)
}

output "bastion_kubectl" {
  description = "kubectl command using the local proxy once the bastion_ssh command is running"
  value       = "HTTPS_PROXY=localhost:8888 kubectl get pods --all-namespaces"
}