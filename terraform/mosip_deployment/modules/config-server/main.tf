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
    "global"                    = { namespace = "default" }
    "keycloak-host"             = { namespace = "keycloak" }
    "activemq-activemq-artemis-share" = { namespace = "activemq" }
    "s3"                        = { namespace = "s3" }
    "msg-gateway"               = { namespace = "msg-gateways" }
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
    "global"                    = { namespace = "default" }
    "keycloak-host"             = { namespace = "keycloak" }
    "activemq-activemq-artemis-share" = { namespace = "activemq" }
    "s3"                        = { namespace = "s3" }
    "msg-gateway"               = { namespace = "msg-gateways" }
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

  set {
    name  = "gitRepo.uri"
    value = var.git_repo_uri
  }

  set {
    name  = "gitRepo.version"
    value = var.git_repo_version
  }

  set {
    name  = "gitRepo.searchPaths"
    value = var.git_search_folders
  }

  set {
    name  = "gitRepo.private"
    value = tostring(var.git_private)
  }

  set {
    name  = "gitRepo.username"
    value = var.git_username
  }

  set_sensitive {
    name  = "gitRepo.token"
    value = var.git_token
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