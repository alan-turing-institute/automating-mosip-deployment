output "namespace" {
  description = "The namespace where IAM is deployed"
  value       = kubernetes_namespace_v1.keycloak.metadata[0].name
}

output "keycloak_status" {
  description = "Status of Keycloak deployment"
  value       = helm_release.keycloak.status
}

output "keycloak_init_status" {
  description = "Status of Keycloak initialization"
  value       = helm_release.keycloak_init.status
}

output "smtp_configured" {
  description = "Whether SMTP is configured"
  value       = var.smtp_auth && var.smtp_host != "" && var.smtp_port != ""
} 