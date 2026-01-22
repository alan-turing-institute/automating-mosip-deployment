output "namespace" {
  description = "The namespace where admin is installed"
  value       = kubernetes_namespace.admin.metadata[0].name
}

output "admin_ui_url" {
  description = "The URL for accessing the admin UI"
  value       = "https://${data.kubernetes_config_map.global.data["mosip-admin-host"]}/admin-ui/"
} 