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
  timeout    = 1200

  set {
    name  = "mosipDataGithubBranch"
    value = var.mosip_data_github_branch
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
    kubernetes_secret.db_common_secrets
  ]
} 