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

# Get global config
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Create namespace for postgres
resource "kubernetes_namespace" "postgres" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Install Postgres using Helm
resource "helm_release" "postgres" {
  name       = "postgres"
  namespace  = kubernetes_namespace.postgres.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = var.chart_version
  timeout    = 600

  values = [
    file("${path.module}/values.yaml")
  ]

  # Override image repository to use mosipid for Bitnami images
  set {
    name  = "image.repository"
    value = "${var.bitnami_image_repository}/postgresql"
  }

  depends_on = [kubernetes_namespace.postgres]
}

# Initialize Postgres databases using Helm
resource "helm_release" "postgres_init" {
  name       = "postgres-init"
  namespace  = kubernetes_namespace.postgres.metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "postgres-init"
  version    = var.init_chart_version
  timeout    = 600

  values = [
    file("${path.module}/init_values.yaml")
  ]

  depends_on = [helm_release.postgres]
}

# Create Istio Gateway for Postgres
resource "kubernetes_manifest" "postgres_gateway" {
  count = var.enable_istio ? 1 : 0

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"
    metadata = {
      name      = "postgres"
      namespace = kubernetes_namespace.postgres.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway-internal"
      }
      servers = [
        {
          port = {
            number   = 5432
            name     = "postgres"
            protocol = "TCP"
          }
          hosts = [data.kubernetes_config_map_v1.global.data["mosip-postgres-host"]]
        }
      ]
    }
  }

  depends_on = [helm_release.postgres_init]
}

# Create Istio Virtual Service for Postgres
resource "kubernetes_manifest" "postgres_virtualservice" {
  count = var.enable_istio ? 1 : 0

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "postgres"
      namespace = kubernetes_namespace.postgres.metadata[0].name
    }
    spec = {
      hosts    = ["*"]
      gateways = ["postgres"]
      tcp = [
        {
          match = [
            {
              port = 5432
            }
          ]
          route = [
            {
              destination = {
                host = "postgres-postgresql"
                port = {
                  number = 5432
                }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.postgres_gateway]
} 