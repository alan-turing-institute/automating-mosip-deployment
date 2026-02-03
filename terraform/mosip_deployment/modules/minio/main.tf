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

# Create namespace for MinIO
resource "kubernetes_namespace" "minio" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Install MinIO using Helm
resource "helm_release" "minio" {
  count = var.enable_minio ? 1 : 0

  name       = "minio"
  namespace  = kubernetes_namespace.minio.metadata[0].name
  repository = "mosip"
  chart      = "minio"
  version    = var.chart_version

  values = [
    file("${path.module}/values.yaml")
  ]

  # Override MinIO subchart image repository to use mosipid for Bitnami images
  # Set both paths to ensure compatibility with different chart versions
  set {
    name  = "image.repository"
    value = "${var.bitnami_image_repository}/minio"
  }

  set {
    name  = "minio.image.repository"
    value = "${var.bitnami_image_repository}/minio"
  }

  depends_on = [kubernetes_namespace.minio]
}

# Create Istio Gateway for MinIO
resource "kubernetes_manifest" "minio_gateway" {
  count = var.enable_minio && var.enable_istio ? 1 : 0
  
  computed_fields = ["metadata.managedFields"]

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"
    metadata = {
      name      = "minio"
      namespace = kubernetes_namespace.minio.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway-internal"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = [data.kubernetes_config_map_v1.global.data["mosip-minio-host"]]
        },
        {
          port = {
            name     = "minio"
            number   = 9000
            protocol = "HTTP"
          }
          hosts = [data.kubernetes_config_map_v1.global.data["mosip-minio-host"]]
        }
      ]
    }
  }

  depends_on = [helm_release.minio]
}

# Create Istio Virtual Service for MinIO
resource "kubernetes_manifest" "minio_virtualservice" {
  count = var.enable_minio && var.enable_istio ? 1 : 0
  
  computed_fields = ["metadata.managedFields"]

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "minio"
      namespace = kubernetes_namespace.minio.metadata[0].name
    }
    spec = {
      hosts    = ["*"]
      gateways = ["minio"]
      http = [
        {
          name = "minio"
          match = [
            {
              port = 9000
            }
          ]
          route = [
            {
              destination = {
                host = "minio"
                port = {
                  number = 9000
                }
              }
            }
          ]
        },
        {
          name = "http"
          match = [
            {
              uri = {
                prefix = "/"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "minio"
                port = {
                  number = 9001
                }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.minio_gateway]
}

# Create s3 namespace for credentials
resource "kubernetes_namespace" "s3" {
  count = var.enable_minio && var.create_s3_namespace ? 1 : 0

  metadata {
    name = "s3"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.minio]
}

# Get MinIO credentials from MinIO secret
data "kubernetes_secret" "minio_creds" {
  count = var.enable_minio && var.create_s3_namespace && var.use_existing_minio ? 1 : 0

  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  depends_on = [helm_release.minio]
}

# Create ConfigMap with S3/MinIO connection details
resource "kubernetes_config_map" "s3" {
  count = var.enable_minio && var.create_s3_namespace ? 1 : 0

  metadata {
    name      = "s3"
    namespace = kubernetes_namespace.s3[0].metadata[0].name
  }

  data = {
    "s3-user-key" = var.use_existing_minio ? data.kubernetes_secret.minio_creds[0].data["root-user"] : var.s3_user_key
    "s3-region"   = var.use_existing_minio ? "" : var.s3_region
  }

  depends_on = [kubernetes_namespace.s3]
}

# Create Secret with S3/MinIO connection credentials
resource "kubernetes_secret" "s3" {
  count = var.enable_minio && var.create_s3_namespace ? 1 : 0

  metadata {
    name      = "s3"
    namespace = kubernetes_namespace.s3[0].metadata[0].name
  }

  data = {
    "s3-user-secret"   = var.use_existing_minio ? data.kubernetes_secret.minio_creds[0].data["root-password"] : var.s3_user_secret
    "s3-pretext-value" = var.s3_pretext_value
  }

  depends_on = [kubernetes_namespace.s3]
} 