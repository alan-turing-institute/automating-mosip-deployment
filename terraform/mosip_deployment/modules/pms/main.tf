resource "kubernetes_namespace" "pms" {
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

# Create configmaps in pms namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.pms.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.pms]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.pms.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.pms]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.pms.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.pms]
}

# Get API and PMP hosts from global configmap
locals {
  internal_api_host = data.kubernetes_config_map.global.data["mosip-api-internal-host"]
  pmp_host         = data.kubernetes_config_map.global.data["mosip-pmp-host"]
}

# Install pms components using Helm
resource "helm_release" "pms_partner" {
  name       = "pms-partner"
  chart      = "pms-partner"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.pms.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "istio.corsPolicy.allowOrigins[0].prefix"
    value = "https://${local.pmp_host}"
  }

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

resource "helm_release" "pms_policy" {
  name       = "pms-policy"
  chart      = "pms-policy"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.pms.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "istio.corsPolicy.allowOrigins[0].prefix"
    value = "https://${local.pmp_host}"
  }

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

resource "helm_release" "pmp_ui" {
  name       = "pmp-ui"
  chart      = "pmp-ui"
  repository = "mosip"
  version    = var.pmp_ui_chart_version
  namespace  = kubernetes_namespace.pms.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "pmp.apiUrl"
    value = "https://${local.internal_api_host}/"
  }

  set {
    name  = "istio.hosts[0]"
    value = local.pmp_host
  }

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