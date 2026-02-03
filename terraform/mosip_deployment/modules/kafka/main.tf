resource "kubernetes_namespace" "kafka" {
  count = var.enable_deployment ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "helm_release" "kafka" {
  count = var.enable_deployment ? 1 : 0

  name       = var.helm_release_name
  namespace  = kubernetes_namespace.kafka[0].metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = var.kafka_chart_version

  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count          = var.replica_count
      zookeeper_replica_count = var.zookeeper_replica_count
      storage_size          = var.storage_size
      zookeeper_storage_size = var.zookeeper_storage_size
    })
  ]

  # Override image repository to use mosipid for Bitnami images
  set {
    name  = "image.repository"
    value = "${var.bitnami_image_repository}/kafka"
  }

  set {
    name  = "zookeeper.image.repository"
    value = "${var.bitnami_image_repository}/zookeeper"
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

  depends_on = [kubernetes_namespace.kafka]
}

resource "helm_release" "kafka_ui" {
  count = var.enable_deployment ? 1 : 0

  name       = "kafka-ui"
  namespace  = kubernetes_namespace.kafka[0].metadata[0].name
  repository = "https://provectus.github.io/kafka-ui-charts"
  chart      = "kafka-ui"
  version    = var.kafka_ui_chart_version

  values = [
    file("${path.module}/ui-values.yaml")
  ]

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

  depends_on = [helm_release.kafka]
}

resource "helm_release" "istio_addons" {
  count = var.enable_deployment ? 1 : 0

  name      = "istio-addons"
  namespace = kubernetes_namespace.kafka[0].metadata[0].name
  chart     = "${path.module}/chart/istio-addons"

  set {
    name  = "kafkaUiHost"
    value = var.kafka_ui_host
  }

  set {
    name  = "installName"
    value = "kafka-ui"
  }

  depends_on = [helm_release.kafka_ui]
} 