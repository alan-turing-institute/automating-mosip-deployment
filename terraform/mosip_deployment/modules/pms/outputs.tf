output "namespace" {
  description = "The namespace where pms is deployed"
  value       = kubernetes_namespace.pms.metadata[0].name
}

output "pms_status" {
  description = "Status of PMS deployment"
  value = {
    partner_status = helm_release.pms_partner.status
    policy_status = helm_release.pms_policy.status
    ui_status = helm_release.pmp_ui.status
  }
}

output "pms_partner_status" {
  description = "Status of pms partner deployment"
  value       = helm_release.pms_partner.status
}

output "pms_policy_status" {
  description = "Status of pms policy deployment"
  value       = helm_release.pms_policy.status
}

output "pmp_ui_status" {
  description = "Status of pmp ui deployment"
  value       = helm_release.pmp_ui.status
}

output "admin_portal_url" {
  description = "URL for accessing the admin portal"
  value       = "https://${local.pmp_host}/pmp-ui/"
} 