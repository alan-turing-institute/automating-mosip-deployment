resource "kubernetes_namespace" "idrepo" {
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

# Create configmaps in idrepo namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.idrepo.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.idrepo]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.idrepo.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.idrepo]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.idrepo.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.idrepo]
}

# Install idrepo components using Helm
resource "helm_release" "idrepo_saltgen" {
  name       = "idrepo-saltgen"
  chart      = "idrepo-saltgen"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.idrepo.metadata[0].name
  timeout    = var.helm_timeout_seconds
  wait       = true
  wait_for_jobs = true

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

resource "helm_release" "credential" {
  name       = "credential"
  chart      = "credential"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.idrepo.metadata[0].name
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

resource "helm_release" "credentialrequest" {
  name       = "credentialrequest"
  chart      = "credentialrequest"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.idrepo.metadata[0].name
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

resource "helm_release" "identity" {
  name       = "identity"
  chart      = "identity"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.idrepo.metadata[0].name
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

resource "helm_release" "vid" {
  name       = "vid"
  chart      = "vid"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.idrepo.metadata[0].name
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