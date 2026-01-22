output "namespace" {
  description = "The namespace where kernel components are deployed"
  value       = kubernetes_namespace.kernel.metadata[0].name
}

output "authmanager_status" {
  description = "Status of authmanager deployment"
  value       = helm_release.authmanager.status
}

output "auditmanager_status" {
  description = "Status of auditmanager deployment"
  value       = helm_release.auditmanager.status
}

output "idgenerator_status" {
  description = "Status of idgenerator deployment"
  value       = helm_release.idgenerator.status
}

output "masterdata_status" {
  description = "Status of masterdata deployment"
  value       = helm_release.masterdata.status
}

output "otpmanager_status" {
  description = "Status of otpmanager deployment"
  value       = helm_release.otpmanager.status
}

output "pridgenerator_status" {
  description = "Status of pridgenerator deployment"
  value       = helm_release.pridgenerator.status
}

output "ridgenerator_status" {
  description = "Status of ridgenerator deployment"
  value       = helm_release.ridgenerator.status
}

output "syncdata_status" {
  description = "Status of syncdata deployment"
  value       = helm_release.syncdata.status
}

output "notifier_status" {
  description = "Status of notifier deployment"
  value       = helm_release.notifier.status
} 