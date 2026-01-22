output "namespace" {
  description = "The namespace where keymanager is deployed"
  value       = kubernetes_namespace_v1.keymanager.metadata[0].name
}

output "is_installed" {
  description = "Whether keymanager is installed"
  value       = true
}

output "helm_release_name" {
  description = "Name of the keymanager Helm release"
  value       = helm_release.keymanager.name
}

output "helm_release_version" {
  description = "Version of the keymanager Helm release"
  value       = helm_release.keymanager.version
}

output "keygen_release_name" {
  description = "Name of the keygen Helm release"
  value       = helm_release.kernel_keygen.name
}

output "keygen_release_version" {
  description = "Version of the keygen Helm release"
  value       = helm_release.kernel_keygen.version
} 