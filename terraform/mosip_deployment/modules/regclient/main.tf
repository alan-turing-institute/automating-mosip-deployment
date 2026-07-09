# Create namespace
resource "kubernetes_namespace" "regclient" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Read global configmap for Helm values (stays in default namespace — not copied to regclient)
data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Read artifactory-share to copy into regclient namespace
data "kubernetes_config_map" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = "artifactory"
  }
}

# Copy artifactory-share into regclient namespace (only configmap regclient needs)
resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.regclient]
}

# Deploy regclient
resource "helm_release" "regclient" {
  name       = "regclient"
  chart      = "regclient"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regclient.metadata[0].name
  wait = true
  timeout    = var.helm_timeout_seconds

  set {
    name  = "regclient.upgradeServerUrl"
    value = "https://${data.kubernetes_config_map.global.data["mosip-regclient-host"]}"
  }

  set {
    name  = "regclient.healthCheckUrl"
    value = "https://${data.kubernetes_config_map.global.data["mosip-api-internal-host"]}/v1/syncdata/actuator/health"
  }

  set {
    name  = "regclient.hostName"
    value = data.kubernetes_config_map.global.data["mosip-api-internal-host"]
  }

  set {
    name  = "istio.host"
    value = data.kubernetes_config_map.global.data["mosip-regclient-host"]
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
    kubernetes_config_map_v1.artifactory_share
  ]
}

resource "kubernetes_limit_range" "default" {
  metadata {
    name      = "default-limits"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "100m"
        memory = "256Mi"
      }
    }
  }
  depends_on = [kubernetes_namespace.regclient]
}
