data "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

resource "kubernetes_namespace_v1" "captcha" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

resource "kubernetes_secret_v1" "mosip_captcha" {
  metadata {
    name      = "mosip-captcha"
    namespace = kubernetes_namespace_v1.captcha.metadata[0].name
  }

  data = {
    "prereg-captcha-site-key"    = var.prereg_captcha_site_key
    "prereg-captcha-secret-key"  = var.prereg_captcha_secret_key
    "resident-captcha-site-key"  = var.resident_captcha_site_key
    "resident-captcha-secret-key" = var.resident_captcha_secret_key
  }

  depends_on = [kubernetes_namespace_v1.captcha]
}

resource "helm_release" "captcha" {
  name       = "captcha"
  chart      = "mosip/captcha"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace_v1.captcha.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "metrics.serviceMonitor.enabled"
    value = tostring(var.metrics_service_monitor_enabled)
  }

  depends_on = [kubernetes_secret_v1.mosip_captcha]
}