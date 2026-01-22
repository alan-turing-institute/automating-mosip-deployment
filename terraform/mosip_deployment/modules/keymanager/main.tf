terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

# Create namespace
resource "kubernetes_namespace_v1" "keymanager" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = var.enable_istio ? "enabled" : "disabled"
    }
  }
}

# Read source configmaps
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

data "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = "artifactory"
  }
}

data "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = "config-server"
  }
}

data "kubernetes_config_map_v1" "softhsm_share" {
  metadata {
    name      = "softhsm-kernel-share"
    namespace = "softhsm"
  }
}

# Copy configmaps to keymanager namespace
resource "kubernetes_config_map_v1" "global_configmap" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace_v1.keymanager.metadata[0].name
  }

  data = data.kubernetes_config_map_v1.global.data

  depends_on = [kubernetes_namespace_v1.keymanager]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace_v1.keymanager.metadata[0].name
  }

  data = data.kubernetes_config_map_v1.artifactory_share.data

  depends_on = [kubernetes_namespace_v1.keymanager]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace_v1.keymanager.metadata[0].name
  }

  data = data.kubernetes_config_map_v1.config_server_share.data

  depends_on = [kubernetes_namespace_v1.keymanager]
}

resource "kubernetes_config_map_v1" "softhsm_share" {
  metadata {
    name      = "softhsm-kernel-share"
    namespace = kubernetes_namespace_v1.keymanager.metadata[0].name
  }

  data = data.kubernetes_config_map_v1.softhsm_share.data

  depends_on = [kubernetes_namespace_v1.keymanager]
}

# Create Istio EnvoyFilter
resource "kubernetes_manifest" "idle_timeout_filter" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "EnvoyFilter"
    metadata = {
      name      = "idle-timeout-inbound-filter"
      namespace = kubernetes_namespace_v1.keymanager.metadata[0].name
    }
    spec = {
      configPatches = [
        {
          applyTo = "NETWORK_FILTER"
          match = {
            context = "SIDECAR_INBOUND"
            listener = {
              filterChain = {
                filter = {
                  name = "envoy.filters.network.tcp_proxy"
                }
              }
            }
          }
          patch = {
            operation = "MERGE"
            value = {
              name = "envoy.filters.network.tcp_proxy"
              typed_config = {
                "@type"        = "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy"
                idle_timeout = "0s"
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_namespace_v1.keymanager]
}

# Install keygen helm chart
resource "helm_release" "kernel_keygen" {
  name       = "kernel-keygen"
  chart      = "keygen"
  repository = "https://mosip.github.io/mosip-helm"
  version    = var.keygen_chart_version
  namespace  = kubernetes_namespace_v1.keymanager.metadata[0].name

  set {
    name  = "springConfigNameEnv"
    value = "kernel"
  }

  set {
    name  = "softHsmCM"
    value = "softhsm-kernel-share"
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  timeout        = 1200 # 20 minutes
  wait           = true
  wait_for_jobs  = true

  depends_on = [
    kubernetes_namespace_v1.keymanager,
    kubernetes_config_map_v1.global_configmap,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_config_map_v1.softhsm_share
  ]
}
resource "time_sleep" "wait_5_min" {
  depends_on = [helm_release.kernel_keygen]
  create_duration = "300s"
}


# Install keymanager helm chart
resource "helm_release" "keymanager" {
  name       = "keymanager"
  chart      = "keymanager"
  repository = "https://mosip.github.io/mosip-helm"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.keymanager.metadata[0].name

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  timeout = 1200 # 20 minutes
  wait    = true

  depends_on = [
    kubernetes_namespace_v1.keymanager,
    kubernetes_config_map_v1.global_configmap,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    kubernetes_config_map_v1.softhsm_share,
    helm_release.kernel_keygen,
    time_sleep.wait_5_min
  ]
} 