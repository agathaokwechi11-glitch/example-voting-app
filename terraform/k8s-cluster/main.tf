resource "kind_cluster" "voting_cluster" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      disable_default_cni = false
      pod_subnet          = "10.244.0.0/16"
      service_subnet      = "10.96.0.0/12"
    }

    node {
      role  = "control-plane"
      image = var.node_image

      extra_port_mappings {
        container_port = 31000
        host_port      = 8080
        listen_address = "127.0.0.1"
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 31001
        host_port      = 8081
        listen_address = "127.0.0.1"
        protocol       = "TCP"
      }
    }

    node {
      role  = "worker"
      image = var.node_image
    }

    node {
      role  = "worker"
      image = var.node_image
    }
  }
}