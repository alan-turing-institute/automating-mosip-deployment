data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

resource "kubernetes_namespace_v1" "artifactory" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "helm_release" "artifactory" {
  name       = "artifactory"
  chart      = "mosip/artifactory"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.artifactory.metadata[0].name

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  depends_on = [kubernetes_namespace_v1.artifactory]
} 