output "namespace" {
  description = "Namespace where Istio is installed"
  value       = var.namespace
}

output "ingress_gateway_service" {
  description = "NodePort service details for the Istio ingress gateway"
  value = var.enable_istio ? {
    public = {
      name = "istio-ingressgateway"
      http_nodeport = 30080
      status_nodeport = 30521
    }
    internal = {
      name = "istio-ingressgateway-internal"
      http_nodeport = 31080
      status_nodeport = 31521
      activemq_nodeport = 31616
      postgres_nodeport = 31432
      minio_nodeport = 30900
    }
  } : null
}

#output "monitoring_status" {
#  description = "Status of Istio monitoring resources"
#  value = {
#    service_monitor = kubernetes_manifest.istio_service_monitor.manifest.metadata.name
#    pod_monitor = kubernetes_manifest.istio_pod_monitor.manifest.metadata.name
#  }
#}