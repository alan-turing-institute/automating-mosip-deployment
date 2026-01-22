output "namespace" {
  description = "The namespace where conf-secrets is deployed"
  value       = var.enable ? kubernetes_namespace_v1.conf_secrets[0].metadata[0].name : null
}

output "is_installed" {
  description = "Whether conf-secrets is installed"
  value       = var.enable
} 