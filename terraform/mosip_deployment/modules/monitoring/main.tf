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
  version          = var.monitoring_crd_version
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
  version    = var.monitoring_version
  timeout    = var.helm_timeout_seconds

  set {
    name  = "windowsExporter.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "grafana.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "grafana.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "prometheusOperator.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "prometheusOperator.resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "kube-state-metrics.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "prometheus-node-exporter.resources.requests.cpu"
    value = "50m"
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