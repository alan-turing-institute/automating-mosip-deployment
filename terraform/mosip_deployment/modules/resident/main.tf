# Resident Module main.tf

resource "kubernetes_namespace" "resident" {
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

# Define source secrets
data "kubernetes_secret" "keycloak_client_secrets" {
  metadata {
    name      = "keycloak-client-secrets"
    namespace = "keycloak"
  }
}

# Create configmaps in resident namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.resident.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.resident]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.resident.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.resident]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.resident.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.resident]
}

# Copy secrets to resident namespace
resource "kubernetes_secret_v1" "keycloak_client_secrets" {
  metadata {
    name      = "keycloak-client-secrets"
    namespace = kubernetes_namespace.resident.metadata[0].name
  }

  data = data.kubernetes_secret.keycloak_client_secrets.data

  depends_on = [kubernetes_namespace.resident]
}

# Create empty resident OIDC client ID secret
resource "kubernetes_secret_v1" "resident_oidc_onboarder_key" {
  metadata {
    name      = "resident-oidc-onboarder-key"
    namespace = kubernetes_namespace.resident.metadata[0].name
  }

  data = {
    "resident-oidc-clientid" = ""
  }

  depends_on = [kubernetes_namespace.resident]
}

# Copy resident OIDC client ID secret to config-server
resource "kubernetes_secret_v1" "resident_oidc_onboarder_key_config" {
  metadata {
    name      = "resident-oidc-onboarder-key"
    namespace = "config-server"
  }

  data = kubernetes_secret_v1.resident_oidc_onboarder_key.data

  depends_on = [kubernetes_secret_v1.resident_oidc_onboarder_key]
}

# Deploy resident service
resource "helm_release" "resident" {
  name       = "resident"
  chart      = "resident"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.resident.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "istio.corsPolicy.allowOrigins[0].prefix"
    value = "https://${data.kubernetes_config_map.global.data["mosip-resident-host"]}"
  }

  set {
    name  = "enable_insecure"
    value = var.enable_insecure
  }

  set {
    name  = "startupProbe.enabled"
    value = tostring(var.startup_probe_enabled)
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = tostring(var.startup_probe_timeout_seconds)
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = tostring(var.startup_probe_initial_delay_seconds)
  }

  set {
    name  = "startupProbe.periodSeconds"
    value = tostring(var.startup_probe_period_seconds)
  }

  set {
    name  = "startupProbe.failureThreshold"
    value = tostring(var.startup_probe_failure_threshold)
  }

  set {
    name  = "readinessProbe.enabled"
    value = tostring(var.readiness_probe_enabled)
  }

  set {
    name  = "readinessProbe.timeoutSeconds"
    value = tostring(var.readiness_probe_timeout_seconds)
  }

  set {
    name  = "readinessProbe.initialDelaySeconds"
    value = tostring(var.readiness_probe_initial_delay_seconds)
  }

  set {
    name  = "readinessProbe.periodSeconds"
    value = tostring(var.readiness_probe_period_seconds)
  }

  set {
    name  = "readinessProbe.failureThreshold"
    value = tostring(var.readiness_probe_failure_threshold)
  }

  set {
    name  = "livenessProbe.enabled"
    value = tostring(var.liveness_probe_enabled)
  }

  set {
    name  = "livenessProbe.timeoutSeconds"
    value = tostring(var.liveness_probe_timeout_seconds)
  }

  set {
    name  = "livenessProbe.initialDelaySeconds"
    value = tostring(var.liveness_probe_initial_delay_seconds)
  }

  set {
    name  = "livenessProbe.periodSeconds"
    value = tostring(var.liveness_probe_period_seconds)
  }

  set {
    name  = "livenessProbe.failureThreshold"
    value = tostring(var.liveness_probe_failure_threshold)
  }

  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_secret_v1.keycloak_client_secrets,
    kubernetes_secret_v1.resident_oidc_onboarder_key_config
  ]
}

# Deploy resident UI
resource "helm_release" "resident_ui" {
  name       = "resident-ui"
  chart      = "resident-ui"
  repository = "mosip"
  version    = var.ui_chart_version
  namespace  = kubernetes_namespace.resident.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "resident.apiHost"
    value = data.kubernetes_config_map.global.data["mosip-api-internal-host"]
  }

  set {
    name  = "istio.hosts[0]"
    value = data.kubernetes_config_map.global.data["mosip-resident-host"]
  }
  set {
  name  = "istio.ingressController.name"
  value = "ingressgateway"  # Public gateway (resident is public-facing)
  }

  set {
  name  = "istio.gateways[0]"
  value = "resident-ui-gateway"
  }

  depends_on = [helm_release.resident]
} 