variable "cluster_name" {
  description = "The name of the local Kubernetes cluster."
  type        = string
  default     = "voting-app-cluster"
}

variable "node_image" {
  description = "The Kind node image version for the cluster."
  type        = string
  default     = "kindest/node:v1.30.0"
}
