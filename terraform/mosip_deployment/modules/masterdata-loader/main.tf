terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
  }
}

# Create namespace
resource "kubernetes_namespace" "masterdata_loader" {
  metadata {
    name = "masterdata-loader"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Copy secrets from other namespaces
resource "kubernetes_secret" "db_common_secrets" {
  metadata {
    name      = "db-common-secrets"
    namespace = kubernetes_namespace.masterdata_loader.metadata[0].name
  }

  data = {
    for key, value in data.kubernetes_secret.db_common_secrets.data : key => value
  }

  type = data.kubernetes_secret.db_common_secrets.type
}

# Data source for db-common-secrets from postgres namespace
data "kubernetes_secret" "db_common_secrets" {
  metadata {
    name      = "db-common-secrets"
    namespace = "postgres"
  }
}

# Deploy masterdata-loader helm chart
resource "helm_release" "masterdata_loader" {
  name       = "masterdata-loader"
  chart      = "mosip/masterdata-loader"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.masterdata_loader.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "mosipDataGithubBranch"
    value = var.mosip_data_github_branch
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
    kubernetes_secret.db_common_secrets
  ]
} 