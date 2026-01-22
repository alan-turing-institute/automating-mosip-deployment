output "namespace" {
  description = "The namespace where Kafka is deployed"
  value       = var.enable_deployment ? kubernetes_namespace.kafka[0].metadata[0].name : null
} 