output "namespace" {
  description = "The namespace where websub is deployed"
  value       = kubernetes_namespace.websub.metadata[0].name
}

output "websub_consolidator_status" {
  description = "Status of websub consolidator deployment"
  value       = helm_release.websub_consolidator.status
}

output "websub_status" {
  description = "Status of websub deployment"
  value       = helm_release.websub.status
} 