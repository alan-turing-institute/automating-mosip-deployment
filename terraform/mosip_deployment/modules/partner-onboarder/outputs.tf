output "namespace" {
  description = "The namespace where partner-onboarder is installed"
  value       = kubernetes_namespace.partner_onboarder.metadata[0].name
}

output "partner_onboarder_status" {
  description = "Status of partner-onboarder deployment"
  value       = helm_release.partner_onboarder
} 