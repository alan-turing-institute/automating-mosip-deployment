output "namespace" {
  description = "The Kubernetes namespace where ClamAV is deployed"
  value       = try(kubernetes_namespace.clamav[0].metadata[0].name, null)
}

output "helm_release_name" {
  description = "The name of the Helm release for ClamAV"
  value       = try(helm_release.clamav[0].name, null)
}

output "helm_release_version" {
  description = "The version of the Helm release for ClamAV"
  value       = try(helm_release.clamav[0].version, null)
} 