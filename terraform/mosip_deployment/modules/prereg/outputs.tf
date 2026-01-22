output "namespace" {
  description = "The namespace where prereg is deployed"
  value       = kubernetes_namespace.prereg.metadata[0].name
}

output "prereg_gateway_status" {
  description = "Status of prereg gateway deployment"
  value       = helm_release.prereg_gateway.status
}

output "prereg_captcha_status" {
  description = "Status of prereg captcha deployment"
  value       = helm_release.prereg_captcha.status
}

output "prereg_application_status" {
  description = "Status of prereg application deployment"
  value       = helm_release.prereg_application.status
}

output "prereg_booking_status" {
  description = "Status of prereg booking deployment"
  value       = helm_release.prereg_booking.status
}

output "prereg_datasync_status" {
  description = "Status of prereg datasync deployment"
  value       = helm_release.prereg_datasync.status
}

output "prereg_batchjob_status" {
  description = "Status of prereg batchjob deployment"
  value       = helm_release.prereg_batchjob.status
}

output "prereg_ui_status" {
  description = "Status of prereg ui deployment"
  value       = helm_release.prereg_ui.status
} 