output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "load_balancer_ip" {
  value       = kubernetes_service.time_api.status[0].load_balancer[0].ingress[0].ip
  description = "Load Balancer IP"
}
