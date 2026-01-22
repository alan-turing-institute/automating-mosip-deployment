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

# Get global config
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Create namespace for SoftHSM
resource "kubernetes_namespace" "softhsm" {
  count = var.enable_softhsm ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Install SoftHSM Kernel using Helm
resource "helm_release" "softhsm_kernel" {
  count      = var.enable_softhsm ? 1 : 0
  name       = "softhsm-kernel"
  namespace  = kubernetes_namespace.softhsm[0].metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "softhsm"
  version    = var.chart_version

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [kubernetes_namespace.softhsm]
}

# Install SoftHSM IDA using Helm
resource "helm_release" "softhsm_ida" {
  count      = var.enable_softhsm ? 1 : 0
  name       = "softhsm-ida"
  namespace  = kubernetes_namespace.softhsm[0].metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "softhsm"
  version    = var.chart_version

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [kubernetes_namespace.softhsm]
} 