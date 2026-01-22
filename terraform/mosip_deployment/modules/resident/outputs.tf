output "namespace" {
  description = "The namespace where resident is deployed"
  value       = kubernetes_namespace.resident.metadata[0].name
}

output "resident_status" {
  description = "Status of resident deployment"
  value       = helm_release.resident.status
}

output "resident_ui_status" {
  description = "Status of resident UI deployment"
  value       = helm_release.resident_ui.status
}

output "resident_ui_url" {
  description = "URL for accessing resident UI"
  value       = "https://${data.kubernetes_config_map.global.data["mosip-resident-host"]}/"
} 