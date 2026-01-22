output "namespace" {
  description = "Namespace where config-server is deployed"
  value       = kubernetes_namespace_v1.config_server.metadata[0].name
}

output "helm_release_name" {
  description = "Name of the config-server Helm release"
  value       = helm_release.config_server.name
}

output "helm_release_version" {
  description = "Version of the config-server Helm release"
  value       = helm_release.config_server.version
}

output "is_installed" {
  description = "Whether config-server is installed"
  value       = true
} 