terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.1"
    }
  }
}

resource "kubernetes_namespace" "clamav" {
  count = var.enable_clamav ? 1 : 0
  metadata {
    name = "clamav"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "helm_release" "clamav" {
  count            = var.enable_clamav ? 1 : 0
  name            = "clamav"
  chart           = "clamav"
  repository      = "https://wiremind.github.io/wiremind-helm-charts"
  namespace       = kubernetes_namespace.clamav[0].metadata[0].name
  wait            = true
  version         = var.helm_chart_version
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  timeout         = var.helm_timeout_seconds

  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count = var.replica_count
      image_repository = var.image_repository
      image_tag = var.image_tag
      image_pull_policy = var.image_pull_policy
    })
  ]

  depends_on = [kubernetes_namespace.clamav]
} 
resource "kubernetes_limit_range" "default" {
  count = var.enable_clamav ? 1 : 0
  metadata {
    name      = "default-limits"
    namespace = kubernetes_namespace.clamav[count.index].metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "100m"
        memory = "256Mi"
      }
    }
  }
  depends_on = [kubernetes_namespace.clamav]
}
