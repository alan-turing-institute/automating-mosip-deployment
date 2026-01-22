resource "kubernetes_namespace" "prereg" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = var.istio_injection_label
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

# Create configmaps in prereg namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.prereg.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.prereg]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.prereg.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.prereg]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.prereg.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.prereg]
}

# Get API and PREREG hosts from global configmap
locals {
  api_host     = data.kubernetes_config_map.global.data["mosip-api-host"]
  prereg_host  = data.kubernetes_config_map.global.data["mosip-prereg-host"]
}

# Install prereg components using Helm
resource "helm_release" "prereg_gateway" {
  name       = "prereg-gateway"
  chart      = "prereg-gateway"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "istio.hosts[0]"
    value = local.prereg_host
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "prereg_captcha" {
  name       = "prereg-captcha"
  chart      = "prereg-captcha"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "prereg_application" {
  name       = "prereg-application"
  chart      = "prereg-application"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  # TODO: Disable startup and readiness probes as a workaround for the not fully set keycloak IDA
  set {
    name  = "startupProbe.enabled"
    value = false
  }

  set {
    name  = "readinessProbe.enabled"
    value = false
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "prereg_booking" {
  name       = "prereg-booking"
  chart      = "prereg-booking"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "prereg_datasync" {
  name       = "prereg-datasync"
  chart      = "prereg-datasync"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "prereg_batchjob" {
  name       = "prereg-batchjob"
  chart      = "prereg-batchjob"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

resource "helm_release" "prereg_ui" {
  name       = "prereg-ui"
  chart      = "prereg-ui"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.prereg.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "prereg.apiHost"
    value = local.prereg_host
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
}

# Apply rate control envoyfilter
resource "kubernetes_manifest" "rate_control_envoyfilter" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "EnvoyFilter"
    metadata = {
      name      = "local-rate-limit"
      namespace = kubernetes_namespace.prereg.metadata[0].name
    }
    spec = {
      workloadSelector = {
        labels = {
          "app.kubernetes.io/instance" = "prereg-ui"
        }
      }
      configPatches = [
        {
          applyTo = "HTTP_FILTER"
          match = {
            context = "SIDECAR_INBOUND"
            listener = {
              filterChain = {
                filter = {
                  name = "envoy.filters.network.http_connection_manager"
                }
              }
            }
          }
          patch = {
            operation = "INSERT_BEFORE"
            value = {
              name = "envoy.filters.http.local_ratelimit"
              typed_config = {
                "@type"    = "type.googleapis.com/udpa.type.v1.TypedStruct"
                type_url  = "type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit"
                value = {
                  stat_prefix = "http_local_rate_limiter"
                  token_bucket = {
                    max_tokens     = var.rate_limit_max_tokens
                    tokens_per_fill = var.rate_limit_tokens_per_fill
                    fill_interval  = var.rate_limit_fill_interval
                  }
                  filter_enabled = {
                    runtime_key = "local_rate_limit_enabled"
                    default_value = {
                      numerator   = 100
                      denominator = "HUNDRED"
                    }
                  }
                  filter_enforced = {
                    runtime_key = "local_rate_limit_enforced"
                    default_value = {
                      numerator   = 100
                      denominator = "HUNDRED"
                    }
                  }
                  response_headers_to_add = [
                    {
                      append = false
                      header = {
                        key   = "x-local-rate-limit"
                        value = "true"
                      }
                    }
                  ]
                }
              }
            }
          }
        }
      ]
    }
  }
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]
} 