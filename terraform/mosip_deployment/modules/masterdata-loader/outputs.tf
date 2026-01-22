output "namespace" {
  description = "The namespace where masterdata-loader is deployed"
  value       = kubernetes_namespace.masterdata_loader.metadata[0].name
}

output "helm_release_name" {
  description = "The name of the Helm release"
  value       = helm_release.masterdata_loader.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.masterdata_loader.status
} 