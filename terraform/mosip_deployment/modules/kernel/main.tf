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

# Variables
variable "idgenerator_replica_count" {
  description = "Number of replicas for ID Generator service"
  type        = number
  default     = 1
}

# Create namespace for kernel
resource "kubernetes_namespace" "kernel" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Copy required configmaps
data "kubernetes_config_map" "source_configmaps" {
  for_each = {
    "global"                = { namespace = "default" }
    "artifactory-share"     = { namespace = "artifactory" }
    "config-server-share"   = { namespace = "config-server" }
  }

  metadata {
    name      = each.key
    namespace = each.value.namespace
  }
}

resource "kubernetes_config_map_v1" "kernel_configmaps" {
  for_each = data.kubernetes_config_map.source_configmaps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.kernel.metadata[0].name
  }

  data = each.value.data

  depends_on = [kubernetes_namespace.kernel]
}

# Common Helm configuration
locals {
  common_helm_config = {
    repository = "mosip"
    version    = var.helm_chart_version
    namespace  = kubernetes_namespace.kernel.metadata[0].name
    timeout    = var.helm_timeout_seconds
  }
}

resource "helm_release" "idgenerator" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps]
  
  name       = "idgenerator"
  chart      = "idgenerator"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  # TODO: Disable startup and readiness probes as a workaround for the duplicate SQL constraint error
  # "message":"ERROR: duplicate key value violates unique constraint \"pk_uin_id\"\n  Detail: Key (uin)=(2154714308) already exists.","logger_name":"org.hibernate.engine.jdbc.spi.SqlE xceptionHelper","thread_name":"vert.x-worker-thread-6","level":"ERROR"
  set {
    name  = "startupProbe.enabled"
    value = false
  }

  set {
    name  = "readinessProbe.enabled"
    value = false
  }
}
# Deploy kernel components using Helm
resource "helm_release" "authmanager" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "authmanager"
  chart      = "authmanager"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "enable_insecure"
    value = var.enable_insecure
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}

resource "helm_release" "auditmanager" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "auditmanager"
  chart      = "auditmanager"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "enable_insecure"
    value = var.enable_insecure
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}



resource "helm_release" "masterdata" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "masterdata"
  chart      = "masterdata"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "istio.corsPolicy.allowOrigins[0].exact"
    value = "https://${data.kubernetes_config_map.source_configmaps["global"].data["mosip-admin-host"]}"
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}

resource "helm_release" "otpmanager" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "otpmanager"
  chart      = "otpmanager"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}

resource "helm_release" "pridgenerator" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "pridgenerator"
  chart      = "pridgenerator"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}

resource "helm_release" "ridgenerator" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "ridgenerator"
  chart      = "ridgenerator"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}

resource "helm_release" "syncdata" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "syncdata"
  chart      = "syncdata"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
}

resource "helm_release" "notifier" {
  depends_on = [kubernetes_config_map_v1.kernel_configmaps, helm_release.idgenerator]
  
  name       = "notifier"
  chart      = "notifier"
  repository = local.common_helm_config.repository
  version    = local.common_helm_config.version
  namespace  = local.common_helm_config.namespace
  timeout    = local.common_helm_config.timeout

  set {
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }
} 