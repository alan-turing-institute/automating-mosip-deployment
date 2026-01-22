output "namespace" {
  description = "The namespace where regclient is deployed"
  value       = kubernetes_namespace.regclient.metadata[0].name
}

output "regclient_status" {
  description = "Status of regclient deployment"
  value       = helm_release.regclient.status
}

output "regclient_url" {
  description = "URL for accessing regclient"
  value       = "https://${data.kubernetes_config_map.global.data["mosip-regclient-host"]}/"
} 