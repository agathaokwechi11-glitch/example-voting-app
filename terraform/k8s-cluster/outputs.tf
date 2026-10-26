output "cluster_endpoint" {
  description = "API server endpoint for the Kubernetes cluster."
  value       = kind_cluster.voting_cluster.endpoint
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the active Kind cluster."
  value       = kind_cluster.voting_cluster.name
}
