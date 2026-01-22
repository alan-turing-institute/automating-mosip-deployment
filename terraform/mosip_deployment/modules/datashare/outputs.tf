output "namespace" {
  description = "The namespace where datashare is deployed"
  value       = kubernetes_namespace.datashare.metadata[0].name
}

output "datashare_status" {
  description = "Status of datashare deployment"
  value       = helm_release.datashare.status
} 