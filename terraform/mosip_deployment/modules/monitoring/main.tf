terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" 
      version = ">= 2.10.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

resource "helm_release" "rancher_monitoring_crd" {
  name             = "rancher-monitoring-crd"
  repository       = "https://charts.rancher.io"
  chart            = "rancher-monitoring-crd"
  namespace        = "cattle-monitoring-system"
  version    = "102.0.5+up40.1.2" # MUST USE THIS VERSION OLD RANCHER !!!
  create_namespace = true
  timeout          = var.helm_timeout_seconds

  lifecycle {
    ignore_changes = [
      namespace
    ]
  }
}

# Wait for CRDs to be fully registered in the cluster
resource "time_sleep" "wait_for_crds" {
  depends_on = [helm_release.rancher_monitoring_crd]
  create_duration = "30s"
}

resource "helm_release" "rancher_monitoring" {
  name       = "rancher-monitoring"
  repository = "https://charts.rancher.io"
  chart      = "rancher-monitoring"
  namespace  = "cattle-monitoring-system"
  version    = "102.0.5+up40.1.2" # MUST USE THIS VERSION OLD RANCHER !!!
  timeout    = var.helm_timeout_seconds

  set {
    name  = "windowsExporter.enabled"
    value = "false"
  }

  depends_on = [
    helm_release.rancher_monitoring_crd,time_sleep.wait_for_crds
  ]

  lifecycle {
    ignore_changes = [
      namespace
    ]
  }
} 