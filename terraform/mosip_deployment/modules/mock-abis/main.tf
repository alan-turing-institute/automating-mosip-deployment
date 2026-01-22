resource "kubernetes_namespace" "abis" {
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

data "kubernetes_config_map" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = "artifactory"
  }
}

data "kubernetes_config_map" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = "config-server"
  }
}

# Create configmaps in abis namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.abis.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.abis]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.abis.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.abis]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.abis.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.abis]
}

# Install mock-abis using Helm
resource "helm_release" "mock_abis" {
  count      = var.enable_mock_abis ? 1 : 0
  name       = "mock-abis"
  chart      = "mock-abis"
  repository = "mosip"
  version    = var.mock_abis_helm_chart_version
  namespace  = kubernetes_namespace.abis.metadata[0].name
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
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

# Install mock-mv using Helm
resource "helm_release" "mock_mv" {
  count      = var.enable_mock_mv ? 1 : 0
  name       = "mock-mv"
  chart      = "mock-mv"
  repository = "mosip"
  version    = var.mock_mv_helm_chart_version
  namespace  = kubernetes_namespace.abis.metadata[0].name
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
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
} 