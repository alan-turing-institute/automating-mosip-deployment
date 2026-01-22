data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

resource "kubernetes_namespace" "activemq" {
  count = var.enable_activemq ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "helm_release" "activemq" {
  count            = var.enable_activemq ? 1 : 0
  name             = "activemq"
  chart            = "${path.module}/charts/activemq-artemis"
  namespace        = kubernetes_namespace.activemq[0].metadata[0].name
  wait             = true
  create_namespace = false

  values = [
    templatefile("${path.module}/values.yaml", {
      istio_enabled      = var.istio_enabled
      activemq_host      = data.kubernetes_config_map.global.data["mosip-activemq-host"]
      ingress_controller = var.ingress_controller
      istio_prefix      = var.istio_prefix
    })
  ]

  depends_on = [
    kubernetes_namespace.activemq
  ]
}