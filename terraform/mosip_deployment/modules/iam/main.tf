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

# Get global config map for host values
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

locals {
  iam_host = data.kubernetes_config_map_v1.global.data["mosip-iam-external-host"]
}

# Create namespace for Keycloak
resource "kubernetes_namespace_v1" "keycloak" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

# Create Keycloak host ConfigMap
resource "kubernetes_config_map_v1" "keycloak_host" {
  metadata {
    name      = "keycloak-host"
    namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
  }

  data = {
    "keycloak-internal-host"       = "keycloak.${kubernetes_namespace_v1.keycloak.metadata[0].name}"
    "keycloak-internal-url"        = "http://keycloak.${kubernetes_namespace_v1.keycloak.metadata[0].name}"
    "keycloak-external-host"       = local.iam_host
    "keycloak-external-url"        = "https://${local.iam_host}"
    "keycloak-internal-service-url" = "http://keycloak.${kubernetes_namespace_v1.keycloak.metadata[0].name}/auth/"
  }
}

# Deploy Keycloak using Helm
resource "helm_release" "keycloak" {
  name       = "keycloak"
  namespace  = kubernetes_namespace_v1.keycloak.metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "keycloak"
  version    = var.chart_version
  timeout    = 600

  values = [
    file("${path.module}/values.yaml")
  ]

  # Image configuration
  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "image.pullPolicy"
    value = var.image_pull_policy
  }

  # Other required settings
  set {
    name  = "auth.adminUser"
    value = "admin"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "proxyAddressForwarding"
    value = "true"
  }

  set {
    name  = "extraEnvVars[0].name"
    value = "KEYCLOAK_EXTRA_ARGS"
  }

  set {
    name  = "extraEnvVars[0].value"
    value = "-Dkeycloak.profile.feature.upload_scripts=enabled"
  }

  # Override PostgreSQL subchart image repository to use mosipid for Bitnami images
  # Set both paths to ensure compatibility with different chart versions
  set {
    name  = "postgresql.primary.image.repository"
    value = "${var.bitnami_image_repository}/postgresql"
  }

  set {
    name  = "postgresql.image.repository"
    value = "${var.bitnami_image_repository}/postgresql"
  }
}

# Create Istio Gateway
resource "kubernetes_manifest" "keycloak_gateway" {
  count = var.enable_istio ? 1 : 0

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"
    metadata = {
      name      = "keycloak"
      namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
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
          hosts = [local.iam_host]
        }
      ]
    }
  }

  depends_on = [helm_release.keycloak]
}

# Create Istio VirtualService
resource "kubernetes_manifest" "keycloak_virtualservice" {
  count = var.enable_istio ? 1 : 0

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "keycloak"
      namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
    }
    spec = {
      hosts    = ["*"]
      gateways = ["keycloak"]
      http = [
        {
          match = [
            {
              uri = {
                prefix = "/oauth2"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "oauth2-proxy.oauth2-proxy.svc.cluster.local"
                port = {
                  number = 80
                }
              }
            }
          ]
          headers = {
            request = {
              set = {
                x-forwarded-proto = "https"
              }
            }
          }
        },
        {
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
                host = "keycloak.${kubernetes_namespace_v1.keycloak.metadata[0].name}.svc.cluster.local"
                port = {
                  number = 80
                }
              }
            }
          ]
          headers = {
            request = {
              set = {
                x-forwarded-proto = "https"
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.keycloak, kubernetes_manifest.keycloak_gateway]
}

# Initialize Keycloak with MOSIP configuration
resource "helm_release" "keycloak_init" {
  depends_on = [helm_release.keycloak]
  name       = "keycloak-init"
  namespace  = kubernetes_namespace_v1.keycloak.metadata[0].name
  repository = "https://mosip.github.io/mosip-helm"
  chart      = "keycloak-init"
  version    = var.init_chart_version

#  values = [
#    file("${path.module}/import-init-values.yaml")
#  ]

  # Frontend URL Configuration
  set {
    name  = "keycloak.realms.mosip.realm_config.attributes.frontendUrl"
    value = "https://${data.kubernetes_config_map_v1.global.data["mosip-iam-external-host"]}/auth"
  }


  # SMTP Configuration
  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.host"
    value = var.smtp_host
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.port"
    value = var.smtp_port
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.from"
    value = var.smtp_from
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.starttls"
    value = var.smtp_starttls
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.auth"
    value = var.smtp_auth
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.ssl"
    value = var.smtp_ssl
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.user"
    value = var.smtp_username
  }

  set {
    name  = "keycloak.realms.mosip.realm_config.smtpServer.password"
    value = var.smtp_password
  }
} 