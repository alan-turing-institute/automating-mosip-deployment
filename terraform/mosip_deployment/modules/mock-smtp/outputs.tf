output "namespace" {
  value = kubernetes_namespace.mock_smtp.metadata[0].name
}

output "helm_release_status" {
  value = helm_release.mock_smtp.status
} 