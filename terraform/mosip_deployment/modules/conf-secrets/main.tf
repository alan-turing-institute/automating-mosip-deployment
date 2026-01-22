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
  timeout    = 600
} 