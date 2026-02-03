resource "kubernetes_namespace" "partner_onboarder" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

# Define source configmaps and secrets
data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Define source configmaps and secrets
data "kubernetes_config_map" "s3" {
  metadata {
    name      = "s3"
    namespace = "s3"
  }
}

data "kubernetes_config_map" "keycloak_env_vars" {
  metadata {
    name      = "keycloak-env-vars"
    namespace = "keycloak"
  }
}

data "kubernetes_config_map" "keycloak_host" {
  metadata {
    name      = "keycloak-host"
    namespace = "keycloak"
  }
}

data "kubernetes_secret" "s3" {
  metadata {
    name      = "s3"
    namespace = "s3"
  }
}

data "kubernetes_secret" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = "keycloak"
  }
}

data "kubernetes_secret" "keycloak_client_secrets" {
  metadata {
    name      = "keycloak-client-secrets"
    namespace = "keycloak"
  }
}

# Create configmaps in partner-onboarder namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.partner_onboarder.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.partner_onboarder]
}

resource "kubernetes_config_map_v1" "keycloak_env_vars" {
  metadata {
    name      = "keycloak-env-vars"
    namespace = kubernetes_namespace.partner_onboarder.metadata[0].name
  }

  data = data.kubernetes_config_map.keycloak_env_vars.data

  depends_on = [kubernetes_namespace.partner_onboarder]
}

resource "kubernetes_config_map_v1" "keycloak_host" {
  metadata {
    name      = "keycloak-host"
    namespace = kubernetes_namespace.partner_onboarder.metadata[0].name
  }

  data = data.kubernetes_config_map.keycloak_host.data

  depends_on = [kubernetes_namespace.partner_onboarder]
}

# Create secrets in partner-onboarder namespace
resource "kubernetes_secret" "s3" {
  metadata {
    name      = "s3"
    namespace = kubernetes_namespace.partner_onboarder.metadata[0].name
  }

  data = data.kubernetes_secret.s3.data

  depends_on = [kubernetes_namespace.partner_onboarder]
}

resource "kubernetes_secret" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.partner_onboarder.metadata[0].name
  }

  data = data.kubernetes_secret.keycloak.data

  depends_on = [kubernetes_namespace.partner_onboarder]
}

resource "kubernetes_secret" "keycloak_client_secrets" {
  metadata {
    name      = "keycloak-client-secrets"
    namespace = kubernetes_namespace.partner_onboarder.metadata[0].name
  }

  data = data.kubernetes_secret.keycloak_client_secrets.data

  depends_on = [kubernetes_namespace.partner_onboarder]
}

# Install partner-onboarder
resource "helm_release" "partner_onboarder" {
  name       = "partner-onboarder"
  chart      = "mosip/partner-onboarder"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.partner_onboarder.metadata[0].name

  # Module configuration
  set {
    name  = "onboarding.modules[0].name"
    value = "ida"
  }
  set {
    name  = "onboarding.modules[0].enabled"
    value = var.module_ida_enabled
  }

  set {
    name  = "onboarding.modules[1].name"
    value = "print"
  }
  set {
    name  = "onboarding.modules[1].enabled"
    value = var.module_print_enabled
  }

  set {
    name  = "onboarding.modules[2].name"
    value = "abis"
  }
  set {
    name  = "onboarding.modules[2].enabled"
    value = var.module_abis_enabled
  }

  set {
    name  = "onboarding.modules[3].name"
    value = "resident"
  }
  set {
    name  = "onboarding.modules[3].enabled"
    value = var.module_resident_enabled
  }

  set {
    name  = "onboarding.modules[4].name"
    value = "mobileid"
  }
  set {
    name  = "onboarding.modules[4].enabled"
    value = var.module_mobileid_enabled
  }

  set {
    name  = "onboarding.modules[5].name"
    value = "digitalcard"
  }
  set {
    name  = "onboarding.modules[5].enabled"
    value = var.module_digitalcard_enabled
  }

  set {
    name  = "onboarding.modules[6].name"
    value = "esignet"
  }
  set {
    name  = "onboarding.modules[6].enabled"
    value = var.module_esignet_enabled
  }

  set {
    name  = "onboarding.modules[7].name"
    value = "demo-oidc"
  }
  set {
    name  = "onboarding.modules[7].enabled"
    value = var.module_demo_oidc_enabled
  }

  set {
    name  = "onboarding.modules[8].name"
    value = "resident-oidc"
  }
  set {
    name  = "onboarding.modules[8].enabled"
    value = var.module_resident_oidc_enabled
  }

  set {
    name  = "onboarding.modules[9].name"
    value = "mimoto-keybinding"
  }
  set {
    name  = "onboarding.modules[9].enabled"
    value = var.module_mimoto_keybinding_enabled
  }

  # S3 configuration
  set {
    name  = "onboarding.configmaps.s3.s3-bucket-name"
    value = var.s3_bucket_name
  }

  set {
    name  = "onboarding.configmaps.s3.s3-region"
    value = var.s3_region
  }

  set {
    name  = "onboarding.configmaps.s3.s3-host"
    #value = "https://${data.kubernetes_config_map.global.data["mosip-minio-host"]}:9000"
    value = "http://minio.minio:9000"
  }

  set {
    name  = "onboarding.configmaps.s3.s3-user-key"
    value = data.kubernetes_config_map.s3.data["s3-user-key"]
  }

  # Insecure mode configuration
  set {
    name  = "onboarding.configmaps.onboarding.ENABLE_INSECURE"
    value = var.enable_insecure
  }

  # Startup probe configuration
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
    kubernetes_config_map_v1.keycloak_env_vars,
    kubernetes_config_map_v1.keycloak_host,
    kubernetes_secret.s3,
    kubernetes_secret.keycloak,
    kubernetes_secret.keycloak_client_secrets
  ]

  timeout = var.helm_timeout_seconds
} 