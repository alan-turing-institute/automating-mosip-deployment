resource "kubernetes_namespace" "admin" {
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

# Create configmaps in admin namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.admin.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.admin]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.admin.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.admin]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.admin.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.admin]
}

# Deploy admin-proxy
resource "kubernetes_deployment" "admin_proxy" {
  metadata {
    name      = "admin-proxy"
    namespace = kubernetes_namespace.admin.metadata[0].name
    labels = {
      app = "admin-proxy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "admin-proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "admin-proxy"
        }
      }

      spec {
        container {
          name  = "admin-proxy"
          image = "nginxinc/nginx-unprivileged:1.21.6-alpine"

          port {
            name           = "http"
            container_port = 8080
          }

          liveness_probe {
            http_get {
              path = "/ping"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds       = 20
            timeout_seconds      = 1
            failure_threshold    = 2
            success_threshold    = 1
          }

          readiness_probe {
            http_get {
              path = "/ping"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds       = 10
            timeout_seconds      = 1
            failure_threshold    = 2
            success_threshold    = 1
          }

          volume_mount {
            name       = "nginx-conf"
            mount_path = "/etc/nginx/"
          }
        }

        volume {
          name = "nginx-conf"
          config_map {
            name = kubernetes_config_map.admin_proxy.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "kubernetes_config_map" "admin_proxy" {
  metadata {
    name      = "admin-proxy"
    namespace = kubernetes_namespace.admin.metadata[0].name
  }

  data = {
    "nginx.conf" = file("${path.module}/nginx.conf")
  }

  depends_on = [kubernetes_namespace.admin]
}

resource "kubernetes_service" "admin_proxy" {
  metadata {
    name      = "admin-proxy"
    namespace = kubernetes_namespace.admin.metadata[0].name
    labels = {
      app = "admin-proxy"
    }
  }

  spec {
    type = "ClusterIP"
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = 8080
    }
    selector = {
      app = "admin-proxy"
    }
  }

  depends_on = [kubernetes_deployment.admin_proxy]
}

# Install admin-hotlist
resource "helm_release" "admin_hotlist" {
  name       = "admin-hotlist"
  chart      = "mosip/admin-hotlist"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.admin.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_deployment.admin_proxy
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

# Install admin-service
resource "helm_release" "admin_service" {
  name       = "admin-service"
  chart      = "mosip/admin-service"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.admin.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_deployment.admin_proxy
  ]

  set {
    name  = "istio.corsPolicy.allowOrigins[0].prefix"
    value = "https://${data.kubernetes_config_map.global.data["mosip-admin-host"]}"
  }

  # Admin-Service uses its own probe configuration variables
  set {
    name  = "startupProbe.enabled"
    value = tostring(var.admin_service_startup_probe_enabled)
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = tostring(var.admin_service_startup_probe_timeout_seconds)
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = tostring(var.admin_service_startup_probe_initial_delay_seconds)
  }

  set {
    name  = "startupProbe.periodSeconds"
    value = tostring(var.admin_service_startup_probe_period_seconds)
  }

  set {
    name  = "startupProbe.failureThreshold"
    value = tostring(var.admin_service_startup_probe_failure_threshold)
  }

  set {
    name  = "readinessProbe.enabled"
    value = tostring(var.admin_service_readiness_probe_enabled)
  }

  set {
    name  = "readinessProbe.timeoutSeconds"
    value = tostring(var.admin_service_readiness_probe_timeout_seconds)
  }

  set {
    name  = "readinessProbe.initialDelaySeconds"
    value = tostring(var.admin_service_readiness_probe_initial_delay_seconds)
  }

  set {
    name  = "readinessProbe.periodSeconds"
    value = tostring(var.admin_service_readiness_probe_period_seconds)
  }

  set {
    name  = "readinessProbe.failureThreshold"
    value = tostring(var.admin_service_readiness_probe_failure_threshold)
  }

  set {
    name  = "livenessProbe.enabled"
    value = tostring(var.admin_service_liveness_probe_enabled)
  }

  set {
    name  = "livenessProbe.timeoutSeconds"
    value = tostring(var.admin_service_liveness_probe_timeout_seconds)
  }

  set {
    name  = "livenessProbe.initialDelaySeconds"
    value = tostring(var.admin_service_liveness_probe_initial_delay_seconds)
  }

  set {
    name  = "livenessProbe.periodSeconds"
    value = tostring(var.admin_service_liveness_probe_period_seconds)
  }

  set {
    name  = "livenessProbe.failureThreshold"
    value = tostring(var.admin_service_liveness_probe_failure_threshold)
  }

  timeout = var.helm_timeout_seconds
}

# Install admin-ui
resource "helm_release" "admin_ui" {
  name       = "admin-ui"
  chart      = "mosip/admin-ui"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.admin.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_deployment.admin_proxy
  ]

  set {
    name  = "admin.apiUrl"
    value = "https://${data.kubernetes_config_map.global.data["mosip-api-internal-host"]}/v1/"
  }

  set {
    name  = "istio.hosts[0]"
    value = "${data.kubernetes_config_map.global.data["mosip-admin-host"]}"
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
} 