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

locals {
  istio_charts = {
    addons = {
      name             = "istio-addons"
      chart           = "${path.module}/chart/istio-addons"
      namespace       = var.namespace
      version         = "0.1.0"
      cleanup_on_fail = true
      wait           = true
      values         = [
        yamlencode({
          publicHost = data.kubernetes_config_map_v1.global.data["mosip-api-host"]
          internalHost = data.kubernetes_config_map_v1.global.data["mosip-api-internal-host"]
          proxyProtocol = {
            enabled = var.proxy_protocol_enabled
          }
        })
      ]
    }
  }
}

# Get global configmap data
data "kubernetes_config_map_v1" "global" {
  metadata {
    name = "global"
    namespace = "default"
  }
}

# Reference existing istio-system namespace instead of creating it
data "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

## Deploy Istio monitoring resources
#resource "kubernetes_manifest" "istio_service_monitor" {
#  manifest = yamldecode(file("${path.module}/istio-monitoring/ServiceMonitor.yaml"))
#
#  depends_on = [data.kubernetes_namespace.istio_system]
#}
#
#resource "kubernetes_manifest" "istio_pod_monitor" {
#  manifest = yamldecode(file("${path.module}/istio-monitoring/PodMonitor.yaml"))
#
#  depends_on = [data.kubernetes_namespace.istio_system]
#}

# Install Istio Addons (gateways, proxy protocol, auth policies)
resource "helm_release" "istio_addons" {
  count = var.enable_istio ? 1 : 0
  depends_on = [data.kubernetes_namespace.istio_system]

  name             = local.istio_charts.addons.name
  chart           = local.istio_charts.addons.chart
  namespace       = local.istio_charts.addons.namespace
  version         = local.istio_charts.addons.version
  cleanup_on_fail = local.istio_charts.addons.cleanup_on_fail
  wait           = local.istio_charts.addons.wait
  values         = local.istio_charts.addons.values
} 