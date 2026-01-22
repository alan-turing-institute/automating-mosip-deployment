output "namespace" {
  description = "The namespace where mock services are deployed"
  value       = kubernetes_namespace.abis.metadata[0].name
}

output "mock_abis_status" {
  description = "Status of mock-abis deployment"
  value       = var.enable_mock_abis ? helm_release.mock_abis[0].status : null
}

output "mock_mv_status" {
  description = "Status of mock-mv deployment"
  value       = var.enable_mock_mv ? helm_release.mock_mv[0].status : null
} 