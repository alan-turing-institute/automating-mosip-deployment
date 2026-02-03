resource "kubernetes_namespace" "mock_smtp" {
  metadata {
    name = "mock-smtp"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Define source configmap
data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Create configmap in mock-smtp namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.mock_smtp.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.mock_smtp]
}

resource "helm_release" "mock_smtp" {
  name             = "mock-smtp"
  chart            = "mosip/mock-smtp"
  namespace        = kubernetes_namespace.mock_smtp.metadata[0].name
  version          = var.helm_version
  create_namespace = false

  set {
    name  = "istio.hosts[0]"
    value = var.mock_smtp_host
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

  timeout = var.helm_timeout_seconds

  depends_on = [
    kubernetes_namespace.mock_smtp,
    kubernetes_config_map_v1.global
  ]
} 