output "namespace" {
  description = "The name of the namespace"
  value       = kubernetes_namespace.landing_page.metadata[0].name
}

output "helm_release_status" {
  description = "The status of the helm release"
  value       = helm_release.landing_page.status
}