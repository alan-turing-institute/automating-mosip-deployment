resource "kubernetes_namespace" "ida" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
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

data "kubernetes_config_map" "softhsm_ida_share" {
  metadata {
    name      = "softhsm-ida-share"
    namespace = "softhsm"
  }
}

# Create configmaps in ida namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.ida.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.ida]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.ida.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.ida]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.ida.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.ida]
}

resource "kubernetes_config_map_v1" "softhsm_ida_share" {
  metadata {
    name      = "softhsm-ida-share"
    namespace = kubernetes_namespace.ida.metadata[0].name
  }

  data = data.kubernetes_config_map.softhsm_ida_share.data

  depends_on = [kubernetes_namespace.ida]
}

# Install ida-keygen
resource "helm_release" "ida_keygen" {
  name       = "ida-keygen"
  chart      = "mosip/keygen"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.ida.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_config_map_v1.softhsm_ida_share
  ]

  set {
    name  = "springConfigNameEnv"
    value = "id-authentication"
  }

  set {
    name  = "softHsmCM"
    value = "softhsm-ida-share"
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "90"
  }

  timeout = var.helm_timeout
}

# Install ida-auth
resource "helm_release" "ida_auth" {
  name       = "ida-auth"
  chart      = "mosip/ida-auth"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.ida.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_config_map_v1.softhsm_ida_share,
    helm_release.ida_keygen
  ]

  set {
    name  = "enable_insecure"
    value = var.enable_insecure
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "90"
  }

  timeout = var.helm_timeout
}

# Install ida-internal
resource "helm_release" "ida_internal" {
  name       = "ida-internal"
  chart      = "mosip/ida-internal"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.ida.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_config_map_v1.softhsm_ida_share,
    helm_release.ida_auth
  ]

  set {
    name  = "enable_insecure"
    value = var.enable_insecure
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "90"
  }

  timeout = var.helm_timeout
}

# Install ida-otp
resource "helm_release" "ida_otp" {
  name       = "ida-otp"
  chart      = "mosip/ida-otp"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.ida.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_config_map_v1.softhsm_ida_share,
    helm_release.ida_internal
  ]

  set {
    name  = "enable_insecure"
    value = var.enable_insecure
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "90"
  }

  timeout = var.helm_timeout
} 