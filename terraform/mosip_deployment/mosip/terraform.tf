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
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
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

# Verify infrastructure is deployed by checking for Istio namespace
data "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

# Verify Longhorn storage class exists
data "kubernetes_storage_class_v1" "longhorn" {
  metadata {
    name = "longhorn"
  }
}

# Get global configmap (created by infrastructure)
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}
