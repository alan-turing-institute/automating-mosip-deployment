output "namespace" {
  description = "The namespace where packetmanager is deployed"
  value       = kubernetes_namespace.packetmanager.metadata[0].name
}

output "packetmanager_status" {
  description = "Status of packetmanager deployment"
  value       = helm_release.packetmanager.status
} 