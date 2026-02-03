resource "kubernetes_namespace" "print" {
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

# Create configmaps in print namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.print.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.print]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.print.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.print]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.print.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.print]
}

# Install print-service
resource "helm_release" "print_service" {
  name       = "print-service"
  chart      = "mosip/print-service"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.print.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]

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

  timeout = var.helm_timeout_seconds
} 