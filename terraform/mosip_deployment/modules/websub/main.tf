resource "kubernetes_namespace" "websub" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = var.istio_injection_label
    }
  }
}


# Define source configmaps
data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

data "kubernetes_config_map" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = "config-server"
  }
}

# Create configmaps in websub namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.websub.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.websub]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.websub.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.websub]
}

resource "helm_release" "websub_consolidator" {
  name       = "websub-consolidator"
  chart      = "websub-consolidator"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.websub.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "websub" {
  name       = "websub"
  chart      = "websub"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.websub.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  depends_on = [helm_release.websub_consolidator]
} 