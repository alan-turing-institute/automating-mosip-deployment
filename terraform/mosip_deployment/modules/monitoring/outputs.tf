output "monitoring_namespace" {
  description = "The namespace where monitoring is deployed"
  value       = var.monitoring_namespace
}

output "monitoring_crd_status" {
  description = "Status of the monitoring CRD deployment"
  value       = helm_release.rancher_monitoring_crd.status
}

output "monitoring_status" {
  description = "Status of the monitoring deployment"
  value       = helm_release.rancher_monitoring.status
} 