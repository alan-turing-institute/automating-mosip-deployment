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

# Create namespace for landing-page
resource "kubernetes_namespace" "landing_page" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Create new ConfigMap with global data
resource "kubernetes_config_map_v1" "landing_page_config" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.landing_page.metadata[0].name
  }

  data = {
    "installation-name"              = data.kubernetes_config_map_v1.global.data["installation-name"]
    "installation-domain"           = data.kubernetes_config_map_v1.global.data["installation-domain"]
    "mosip-api-host"               = data.kubernetes_config_map_v1.global.data["mosip-api-host"]
    "mosip-api-internal-host"      = data.kubernetes_config_map_v1.global.data["mosip-api-internal-host"]
    "mosip-admin-host"             = data.kubernetes_config_map_v1.global.data["mosip-admin-host"]
    "mosip-prereg-host"            = data.kubernetes_config_map_v1.global.data["mosip-prereg-host"]
    "mosip-kafka-host"             = data.kubernetes_config_map_v1.global.data["mosip-kafka-host"]
    "mosip-kibana-host"            = data.kubernetes_config_map_v1.global.data["mosip-kibana-host"]
    "mosip-activemq-host"          = data.kubernetes_config_map_v1.global.data["mosip-activemq-host"]
    "mosip-minio-host"             = data.kubernetes_config_map_v1.global.data["mosip-minio-host"]
    "mosip-iam-external-host"      = data.kubernetes_config_map_v1.global.data["mosip-iam-external-host"]
    "mosip-regclient-host"         = data.kubernetes_config_map_v1.global.data["mosip-regclient-host"]
    "mosip-postgres-host"          = data.kubernetes_config_map_v1.global.data["mosip-postgres-host"]
    "mosip-pmp-host"               = data.kubernetes_config_map_v1.global.data["mosip-pmp-host"]
    "mosip-compliance-host"        = data.kubernetes_config_map_v1.global.data["mosip-compliance-host"]
    "mosip-resident-host"          = data.kubernetes_config_map_v1.global.data["mosip-resident-host"]
    "mosip-esignet-host"           = data.kubernetes_config_map_v1.global.data["mosip-esignet-host"]
    "mosip-smtp-host"              = data.kubernetes_config_map_v1.global.data["mosip-smtp-host"]
  }

  depends_on = [kubernetes_namespace.landing_page]
}

# Install Landing Page using Helm
resource "helm_release" "landing_page" {
  name       = "landing-page"
  namespace  = kubernetes_namespace.landing_page.metadata[0].name
  repository = "mosip"
  chart      = "landing-page"
  version    = var.chart_version
  timeout    = var.helm_timeout_seconds

  values = [
    file("${path.module}/values.yaml")
  ]

  # Set values from global ConfigMap
  set {
    name  = "landing.version"
    value = var.landing_version
  }

  set {
    name  = "landing.name"
    value = data.kubernetes_config_map_v1.global.data["installation-name"]
  }

  set {
    name  = "landing.api"
    value = data.kubernetes_config_map_v1.global.data["mosip-api-host"]
  }

  set {
    name  = "landing.apiInternal"
    value = data.kubernetes_config_map_v1.global.data["mosip-api-internal-host"]
  }

  set {
    name  = "landing.admin"
    value = data.kubernetes_config_map_v1.global.data["mosip-admin-host"]
  }

  set {
    name  = "landing.prereg"
    value = data.kubernetes_config_map_v1.global.data["mosip-prereg-host"]
  }

  set {
    name  = "landing.kafka"
    value = data.kubernetes_config_map_v1.global.data["mosip-kafka-host"]
  }

  set {
    name  = "landing.kibana"
    value = data.kubernetes_config_map_v1.global.data["mosip-kibana-host"]
  }

  set {
    name  = "landing.activemq"
    value = data.kubernetes_config_map_v1.global.data["mosip-activemq-host"]
  }

  set {
    name  = "landing.minio"
    value = data.kubernetes_config_map_v1.global.data["mosip-minio-host"]
  }

  set {
    name  = "landing.keycloak"
    value = data.kubernetes_config_map_v1.global.data["mosip-iam-external-host"]
  }

  set {
    name  = "landing.regclient"
    value = data.kubernetes_config_map_v1.global.data["mosip-regclient-host"]
  }

  set {
    name  = "landing.postgres.host"
    value = data.kubernetes_config_map_v1.global.data["mosip-postgres-host"]
  }

  set {
    name  = "landing.postgres.port"
    value = "5432"
  }

  set {
    name  = "landing.pmp"
    value = data.kubernetes_config_map_v1.global.data["mosip-pmp-host"]
  }

  set {
    name  = "landing.compliance"
    value = data.kubernetes_config_map_v1.global.data["mosip-compliance-host"]
  }

  set {
    name  = "landing.resident"
    value = data.kubernetes_config_map_v1.global.data["mosip-resident-host"]
  }

  set {
    name  = "landing.esignet"
    value = data.kubernetes_config_map_v1.global.data["mosip-esignet-host"]
  }

  set {
    name  = "landing.smtp"
    value = data.kubernetes_config_map_v1.global.data["mosip-smtp-host"]
  }

  set {
    name  = "landing.healthservices"
    value = var.healthservices_host
  }

  set {
    name  = "istio.host"
    value = data.kubernetes_config_map_v1.global.data["installation-domain"]
  }

  depends_on = [kubernetes_config_map_v1.landing_page_config]
}