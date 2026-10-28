variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "voting-app-cluster"
}

variable "aws_region" {
  description = "AWS region for the EKS cluster and resources."
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.37"
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "desired_node_count" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}
