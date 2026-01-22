output "namespace" {
  description = "The namespace where artifactory is deployed"
  value       = kubernetes_namespace_v1.artifactory.metadata[0].name
}

output "is_installed" {
  description = "Whether artifactory is installed"
  value       = true
}

output "helm_release_name" {
  description = "Name of the artifactory Helm release"
  value       = helm_release.artifactory.name
} 