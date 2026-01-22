resource "kubernetes_namespace" "mosip_file_server" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = var.istio_injection_label
    }
  }
}

# Global config (for hosts)
data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Source configmap from config-server namespace
data "kubernetes_config_map" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = "config-server"
  }
}

# Source Keycloak client secrets (for mosip_regproc_client_secret)
data "kubernetes_secret" "keycloak_client_secrets" {
  metadata {
    name      = "keycloak-client-secrets"
    namespace = "keycloak"
  }
}

# Copy config-server-share configmap into mosip-file-server namespace
resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.mosip_file_server.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.mosip_file_server]
}

# Deploy mosip-file-server via Helm
resource "helm_release" "mosip_file_server" {
  name       = "mosip-file-server"
  chart      = "mosip-file-server"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.mosip_file_server.metadata[0].name
  timeout    = var.helm_timeout_seconds

  # mosipfileserver.host -> FILESERVER_HOST (mosip-api-host)
  set {
    name  = "mosipfileserver.host"
    value = data.kubernetes_config_map_v1.global.data["mosip-api-host"]
  }

  # mosipfileserver.secrets.KEYCLOAK_CLIENT_SECRET from Keycloak secret
  set {
    name  = "mosipfileserver.secrets.KEYCLOAK_CLIENT_SECRET"
    value = data.kubernetes_secret.keycloak_client_secrets.data["mosip_regproc_client_secret"]
  }

  # CORS allowOrigins prefixes
  set {
    name  = "istio.corsPolicy.allowOrigins[0].prefix"
    value = "https://${data.kubernetes_config_map_v1.global.data["mosip-api-host"]}"
  }

  set {
    name  = "istio.corsPolicy.allowOrigins[1].prefix"
    value = "https://${data.kubernetes_config_map_v1.global.data["mosip-api-internal-host"]}"
  }

  set {
    name  = "istio.corsPolicy.allowOrigins[2].prefix"
    value = "https://verifiablecredential.io"
  }

  depends_on = [
    kubernetes_namespace.mosip_file_server,
    kubernetes_config_map_v1.config_server_share,
    data.kubernetes_secret.keycloak_client_secrets
  ]
}


