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

# Get global config map for host values
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Create namespace for config-server
resource "kubernetes_namespace_v1" "config_server" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Copy ConfigMaps from other namespaces
resource "kubernetes_config_map_v1" "config_server_cm" {
  depends_on = [kubernetes_namespace_v1.config_server]

  for_each = {
    "global"                          = { namespace = "default" }
    "keycloak-host"                   = { namespace = "keycloak" }
    "activemq-activemq-artemis-share" = { namespace = "activemq" }
    "s3"                              = { namespace = "s3" }
    "msg-gateway"                     = { namespace = "msg-gateways" }
    "postgres-setup-config"           = { namespace = "postgres" }
  }
  
  metadata {
    name      = each.key
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = {
    for key, value in try(data.kubernetes_config_map_v1.source_configmaps[each.key].data, {}) : key => value
  }
}

# Data source for ConfigMaps
data "kubernetes_config_map_v1" "source_configmaps" {
  for_each = {
    "global"                          = { namespace = "default" }
    "keycloak-host"                   = { namespace = "keycloak" }
    "activemq-activemq-artemis-share" = { namespace = "activemq" }
    "s3"                              = { namespace = "s3" }
    "msg-gateway"                     = { namespace = "msg-gateways" }
    "postgres-setup-config"           = { namespace = "postgres" }
  }
  
  metadata {
    name      = each.key
    namespace = each.value.namespace
  }
}

# Data sources for secrets
data "kubernetes_secret_v1" "source_secrets" {
  for_each = {
    "db-common-secrets"         = { namespace = "postgres" }
    "keycloak"                  = { namespace = "keycloak" }
    "keycloak-client-secrets"   = { namespace = "keycloak" }
    "activemq-activemq-artemis" = { namespace = "activemq" }
    "softhsm-kernel"            = { namespace = "softhsm" }
    "softhsm-ida"               = { namespace = "softhsm" }
    "s3"                        = { namespace = "s3" }
    "msg-gateway"               = { namespace = "msg-gateways" }
    "mosip-captcha"             = { namespace = "captcha" }
    "conf-secrets-various"      = { namespace = "conf-secrets" }
  }
  
  metadata {
    name      = each.key
    namespace = each.value.namespace
  }
}

# Copy secrets with explicit dependencies
# 1. Database secrets first
resource "kubernetes_secret_v1" "db_secrets" {
  depends_on = [kubernetes_namespace_v1.config_server]
  
  metadata {
    name      = "db-common-secrets"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["db-common-secrets"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["db-common-secrets"].type, "Opaque")
}

# 2. Keycloak secrets
resource "kubernetes_secret_v1" "keycloak_secret" {
  depends_on = [kubernetes_secret_v1.db_secrets]
  
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["keycloak"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["keycloak"].type, "Opaque")
}

# 3. Keycloak client secrets (depends on keycloak secret)
resource "kubernetes_secret_v1" "keycloak_client_secrets" {
  depends_on = [kubernetes_secret_v1.keycloak_secret]
  
  metadata {
    name      = "keycloak-client-secrets"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["keycloak-client-secrets"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["keycloak-client-secrets"].type, "Opaque")
}

# 4. ActiveMQ secrets
resource "kubernetes_secret_v1" "activemq_secret" {
  depends_on = [kubernetes_secret_v1.keycloak_client_secrets]
  
  metadata {
    name      = "activemq-activemq-artemis"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["activemq-activemq-artemis"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["activemq-activemq-artemis"].type, "Opaque")
}

# 5. SoftHSM secrets
resource "kubernetes_secret_v1" "softhsm_kernel_secret" {
  depends_on = [kubernetes_secret_v1.activemq_secret]
  
  metadata {
    name      = "softhsm-kernel"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["softhsm-kernel"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["softhsm-kernel"].type, "Opaque")
}

resource "kubernetes_secret_v1" "softhsm_ida_secret" {
  depends_on = [kubernetes_secret_v1.softhsm_kernel_secret]
  
  metadata {
    name      = "softhsm-ida"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["softhsm-ida"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["softhsm-ida"].type, "Opaque")
}

# 6. S3 secrets
resource "kubernetes_secret_v1" "s3_secret" {
  depends_on = [kubernetes_secret_v1.softhsm_ida_secret]
  
  metadata {
    name      = "s3"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["s3"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["s3"].type, "Opaque")
}

# 7. Message gateway secrets
resource "kubernetes_secret_v1" "msg_gateway_secret" {
  depends_on = [kubernetes_secret_v1.s3_secret]
  
  metadata {
    name      = "msg-gateway"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["msg-gateway"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["msg-gateway"].type, "Opaque")
}

# 8. Captcha secrets
resource "kubernetes_secret_v1" "captcha_secret" {
  depends_on = [kubernetes_secret_v1.msg_gateway_secret]
  
  metadata {
    name      = "mosip-captcha"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["mosip-captcha"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["mosip-captcha"].type, "Opaque")
}

# 9. Various configuration secrets
resource "kubernetes_secret_v1" "conf_secrets" {
  depends_on = [kubernetes_secret_v1.captcha_secret]
  
  metadata {
    name      = "conf-secrets-various"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }
  
  data = try(data.kubernetes_secret_v1.source_secrets["conf-secrets-various"].data, {})
  type = try(data.kubernetes_secret_v1.source_secrets["conf-secrets-various"].type, "Opaque")
}

# Create GitHub token secret
resource "kubernetes_secret_v1" "github_token" {
  count = var.git_private ? 1 : 0
  depends_on = [kubernetes_secret_v1.conf_secrets]
  
  metadata {
    name      = "github-token"
    namespace = kubernetes_namespace_v1.config_server.metadata[0].name
  }

  data = {
    "github-token" = var.git_token
  }
}

# Deploy config-server using Helm
resource "helm_release" "config_server" {
  depends_on = [
    kubernetes_namespace_v1.config_server,
    kubernetes_config_map_v1.config_server_cm,
    kubernetes_secret_v1.github_token,
    kubernetes_secret_v1.conf_secrets
  ]
  
  name       = "config-server"
  namespace  = kubernetes_namespace_v1.config_server.metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "config-server"
  version    = var.chart_version
  timeout    = 1800  # 30 minutes

  # Composite profile — MOSIP default; spring_compositeRepos[0] is the mosip-config git repo
  set {
    name  = "spring_profiles.enabled"
    value = "true"
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].type"
    value = "git"
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].uri"
    value = var.git_repo_uri
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].version"
    value = var.git_repo_version
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].searchFolders"
    value = var.git_search_folders
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].private"
    value = tostring(var.git_private)
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].username"
    value = var.git_username
  }

  set_sensitive {
    name  = "spring_profiles.spring_compositeRepos[0].token"
    value = var.git_token
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].spring_cloud_config_server_git_cloneOnStart"
    value = "true"
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].spring_cloud_config_server_git_force_pull"
    value = "true"
  }

  set {
    name  = "spring_profiles.spring_compositeRepos[0].spring_cloud_config_server_git_refreshRate"
    value = "5"
  }

  set {
    name  = "spring_profiles.spring_fail_on_composite_error"
    value = "false"
  }

  set {
    name  = "localRepo.enabled"
    value = "false"
  }

  # extraEnvVars — Spring Cloud Config Server overrides propagated to all config clients
  set {
    name  = "extraEnvVars[0].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_KERNEL_UIN_MIN_UNUSED_THRESHOLD_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[0].value"
    value = var.config_server_uin_min_threshold
  }
  set {
    name  = "extraEnvVars[0].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[1].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_AUTH_SERVER_ADMIN_ALLOWED_AUDIENCE_IDREPO_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[1].value"
    value = var.config_server_auth_audience_idrepo
  }
  set {
    name  = "extraEnvVars[1].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[2].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_IDREPO_CREDENTIAL_REQUEST_ENABLE_CONVENTION_BASED_ID_IDREPO_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[2].value"
    value = var.config_server_credential_convention_id_enabled
  }
  set {
    name  = "extraEnvVars[2].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[3].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_AUTH_SERVER_ADMIN_ALLOWED_AUDIENCE_KERNEL_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[3].value"
    value = var.config_server_auth_audience_kernel
  }
  set {
    name  = "extraEnvVars[3].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[4].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_KERNEL_VID_MIN_UNUSED_THRESHOLD_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[4].value"
    value = var.config_server_vid_min_threshold
  }
  set {
    name  = "extraEnvVars[4].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[5].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_PREREGISTRATION_CAPTCHA_ENABLE_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[5].value"
    value = var.config_server_captcha_enable
  }
  set {
    name  = "extraEnvVars[5].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[6].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_ESIGNET_CAPTCHA_REQUIRED_ESIGNET_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[6].value"
    value = var.config_server_esignet_captcha_required
  }
  set {
    name  = "extraEnvVars[6].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[7].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_DATABASE_HOSTNAME_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[7].value"
    value = "postgres-postgresql.postgres"
  }
  set {
    name  = "extraEnvVars[7].enabled"
    value = "true"
  }
  set {
    name  = "extraEnvVars[8].name"
    value = "SPRING_CLOUD_CONFIG_SERVER_OVERRIDES_MOSIP_DATABASE_PORT_OVERRIDE"
  }
  set {
    name  = "extraEnvVars[8].value"
    value = "5432"
  }
  set {
    name  = "extraEnvVars[8].enabled"
    value = "true"
  }

  # Startup Probe Configuration
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

  # Readiness Probe Configuration
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

  # Liveness Probe Configuration
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
} 