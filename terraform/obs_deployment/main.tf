terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.36.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_version
  namespace        = var.ingress_nginx_namespace
  create_namespace = true

  values = [
    yamlencode({
      controller = {
        service = {
          type      = var.ingress_nginx_values.controller.service.type
          nodePorts = var.ingress_nginx_values.controller.service.nodePorts
        }
        config = {
          "use-forwarded-headers" = var.ingress_nginx_values.controller.config.use_forwarded_headers
        }
      }
    })
  ]

  depends_on = [helm_release.longhorn]
}

resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  version          = var.longhorn_version
  namespace        = var.longhorn_namespace
  create_namespace = true

  set {
    name  = "defaultSettings.guaranteedEngineManagerCPU"
    value = "5"
  }

  set {
    name  = "defaultSettings.guaranteedReplicaManagerCPU"
    value = "5"
  }

  set {
    name  = "persistence.defaultClassReplicaCount"
    value = "1"
  }

  set {
    name  = "defaultSettings.defaultReplicaCount"
    value = "1"
  }

  set {
    name  = "persistence.defaultClass"
    value = "true"
  }
}

resource "kubernetes_persistent_volume" "filesystem_pv" {
  metadata {
    name = "filesystem-pv"
  }
  spec {
    capacity = {
      storage = var.filesystem_pv_size
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = "longhorn"
    persistent_volume_source {
      csi {
        driver        = "driver.longhorn.io"
        volume_handle = "filesystem-pv"
        fs_type      = "ext4"
      }
    }
  }
  depends_on = [helm_release.longhorn]
}

resource "kubernetes_persistent_volume_claim" "filesystem_pvc" {
  metadata {
    name = "filesystem-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.filesystem_pv_size
      }
    }
    volume_name = kubernetes_persistent_volume.filesystem_pv.metadata[0].name
  }
  depends_on = [kubernetes_persistent_volume.filesystem_pv]
}

resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  version          = var.rancher_version
  namespace        = var.rancher_namespace
  create_namespace = true

  values = [
    yamlencode({
      hostname = var.rancher_hostname
      ingress = {
        enabled = true
        includeDefaultExtraAnnotations = true
        extraAnnotations = {
          "kubernetes.io/ingress.class" = "nginx"
        }
      }
      rancherImage = "rancher/rancher"
      replicas = var.rancher_replicas
      tls = "external"
      bootstrapPassword = var.rancher_bootstrap_password
    })
  ]

  depends_on = [helm_release.ingress_nginx]
}

data "kubernetes_secret" "rancher_bootstrap" {
  metadata {
    name      = "bootstrap-secret"
    namespace = var.rancher_namespace
  }
  depends_on = [helm_release.rancher]
}

output "rancher_bootstrap_password" {
  description = "Bootstrap password for Rancher"
  value       = data.kubernetes_secret.rancher_bootstrap.data["bootstrapPassword"]
  sensitive   = true
} 