resource "kubernetes_namespace" "msg_gateway" {
  count = var.msg_gateway_enabled ? 1 : 0
  
  metadata {
    name = "msg-gateways"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_config_map" "msg_gateway" {
  count = var.msg_gateway_enabled ? 1 : 0
  
  metadata {
    name      = "msg-gateway"
    namespace = kubernetes_namespace.msg_gateway[0].metadata[0].name
  }

  data = {
    "smtp-host"     = var.smtp_host
    "sms-host"      = var.sms_host
    "smtp-port"     = var.smtp_port
    "sms-port"      = var.sms_port
    "smtp-username" = var.smtp_username
    "sms-username"  = var.sms_username
  }

  depends_on = [kubernetes_namespace.msg_gateway]
}

resource "kubernetes_secret" "msg_gateway" {
  count = var.msg_gateway_enabled ? 1 : 0
  
  metadata {
    name      = "msg-gateway"
    namespace = kubernetes_namespace.msg_gateway[0].metadata[0].name
  }

  data = {
    "smtp-secret"  = var.smtp_secret
    "sms-secret"   = var.sms_secret
    "sms-authkey"  = var.sms_authkey
  }

  depends_on = [kubernetes_namespace.msg_gateway]
} 