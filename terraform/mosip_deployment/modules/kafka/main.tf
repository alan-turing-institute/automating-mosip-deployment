resource "kubernetes_namespace" "kafka" {
  count = var.enable_deployment ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "helm_release" "kafka" {
  count = var.enable_deployment ? 1 : 0

  name       = var.helm_release_name
  namespace  = kubernetes_namespace.kafka[0].metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = var.kafka_chart_version

  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count          = var.replica_count
      zookeeper_replica_count = var.zookeeper_replica_count
      storage_size          = var.storage_size
      zookeeper_storage_size = var.zookeeper_storage_size
    })
  ]

  # Override image repository to use mosipid for Bitnami images
  set {
    name  = "image.repository"
    value = "${var.bitnami_image_repository}/kafka"
  }

  set {
    name  = "zookeeper.image.repository"
    value = "${var.bitnami_image_repository}/zookeeper"
  }

  depends_on = [kubernetes_namespace.kafka]
}

resource "helm_release" "kafka_ui" {
  count = var.enable_deployment ? 1 : 0

  name       = "kafka-ui"
  namespace  = kubernetes_namespace.kafka[0].metadata[0].name
  repository = "https://provectus.github.io/kafka-ui-charts"
  chart      = "kafka-ui"
  version    = var.kafka_ui_chart_version

  values = [
    file("${path.module}/ui-values.yaml")
  ]

  depends_on = [helm_release.kafka]
}

resource "helm_release" "istio_addons" {
  count = var.enable_deployment ? 1 : 0

  name      = "istio-addons"
  namespace = kubernetes_namespace.kafka[0].metadata[0].name
  chart     = "${path.module}/chart/istio-addons"

  set {
    name  = "kafkaUiHost"
    value = var.kafka_ui_host
  }

  set {
    name  = "installName"
    value = "kafka-ui"
  }

  depends_on = [helm_release.kafka_ui]
} 