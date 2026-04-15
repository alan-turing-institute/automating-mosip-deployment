# Infrastructure Outputs
# These outputs can be used by MOSIP deployment to verify infrastructure is ready

output "csi_deployment_status" {
  description = "Status of CSI deployments"
  value       = var.longhorn_enable ? module.longhorn.csi_deployment_status : null
}

output "istio_status" {
  description = "Status of Istio deployment"
  value = var.enable_istio ? {
    namespace = module.istio.namespace
    ingress_gateway = module.istio.ingress_gateway_service
  } : null
}

output "longhorn_storage_class" {
  description = "Longhorn storage class name"
  value       = var.longhorn_storage_class_name
}

output "istio_namespace" {
  description = "Istio namespace"
  value       = var.istio_namespace
}

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = var.monitoring_namespace
}
