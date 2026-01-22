resource "kubernetes_namespace" "httpbin" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_service_account" "httpbin" {
  metadata {
    name      = "httpbin"
    namespace = kubernetes_namespace.httpbin.metadata[0].name
  }
}

resource "kubernetes_deployment" "httpbin" {
  metadata {
    name      = "httpbin"
    namespace = kubernetes_namespace.httpbin.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "httpbin"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "httpbin"
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.httpbin.metadata[0].name

        container {
          name  = "httpbin"
          image = "docker.io/kennethreitz/httpbin"

          port {
            container_port = 80
          }

          image_pull_policy = "IfNotPresent"
        }
      }
    }
  }
}

resource "kubernetes_service" "httpbin" {
  metadata {
    name      = "httpbin"
    namespace = kubernetes_namespace.httpbin.metadata[0].name
    labels = {
      app     = "httpbin"
      service = "httpbin"
    }
  }

  spec {
    port {
      name        = "http"
      port        = 8000
      target_port = 80
    }

    selector = {
      app = "httpbin"
    }
  }
}

resource "kubernetes_manifest" "httpbin_virtual_service" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "httpbin"
      namespace = kubernetes_namespace.httpbin.metadata[0].name
    }
    spec = {
      hosts = ["*"]
      gateways = [
        "istio-system/internal",
        "istio-system/public"
      ]
      http = [{
        match = [{
          uri = {
            prefix = "/httpbin/"
          }
        }]
        rewrite = {
          uri = "/"
        }
        route = [{
          destination = {
            host = "httpbin"
            port = {
              number = 8000
            }
          }
        }]
        headers = {
          request = {
            set = {
              x-forwarded-proto = "https"
            }
          }
        }
      }]
    }
  }
}

# Add busybox-curl deployment for internal testing
resource "kubernetes_deployment" "busybox_curl" {
  metadata {
    name      = "busybox-curl"
    namespace = kubernetes_namespace.httpbin.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "busybox-curl"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "busybox-curl"
          version = "v1"
        }
      }

      spec {
        container {
          name  = "busybox-curl"
          image = "docker.io/yauritux/busybox-curl:latest"
          
          args = ["sleep", "infinity"]
          
          image_pull_policy = "IfNotPresent"
        }
      }
    }
  }
} 