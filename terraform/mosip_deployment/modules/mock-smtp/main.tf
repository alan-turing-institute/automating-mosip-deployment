resource "kubernetes_namespace" "mock_smtp" {
  metadata {
    name = "mock-smtp"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Define source configmap
data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

# Create configmap in mock-smtp namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.mock_smtp.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.mock_smtp]
}

resource "helm_release" "mock_smtp" {
  name             = "mock-smtp"
  chart            = "mosip/mock-smtp"
  namespace        = kubernetes_namespace.mock_smtp.metadata[0].name
  version          = var.helm_version
  create_namespace = false

  set {
    name  = "istio.hosts[0]"
    value = var.mock_smtp_host
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "90"
  }

  timeout = 1200

  depends_on = [
    kubernetes_namespace.mock_smtp,
    kubernetes_config_map_v1.global
  ]
} 