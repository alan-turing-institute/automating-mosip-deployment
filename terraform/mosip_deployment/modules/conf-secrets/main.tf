terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

# Create namespace for conf-secrets
resource "kubernetes_namespace_v1" "conf_secrets" {
  count = var.enable ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Deploy conf-secrets using Helm
resource "helm_release" "conf_secrets" {
  count      = var.enable ? 1 : 0
  name       = "conf-secrets"
  namespace  = kubernetes_namespace_v1.conf_secrets[0].metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "conf-secrets"
  version    = var.chart_version
  timeout    = var.helm_timeout_seconds
}

resource "kubernetes_limit_range" "default" {
  count = var.enable ? 1 : 0
  metadata {
    name      = "default-limits"
    namespace = kubernetes_namespace_v1.conf_secrets[0].metadata[0].name
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
  depends_on = [kubernetes_namespace_v1.conf_secrets]
}