# Output deployment status
output "longhorn_release" {
  description = "The Longhorn Helm release"
  value       = helm_release.longhorn
}

output "csi_deployment_status" {
  description = "Status of CSI deployments"
  value       = local.deployment_ready
} 