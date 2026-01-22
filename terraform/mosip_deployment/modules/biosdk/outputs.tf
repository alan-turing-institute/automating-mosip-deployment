output "namespace" {
  description = "The namespace where biosdk is deployed"
  value       = kubernetes_namespace.biosdk.metadata[0].name
}

output "biosdk_service_status" {
  description = "Status of biosdk service deployment"
  value       = helm_release.biosdk_service.status
} 