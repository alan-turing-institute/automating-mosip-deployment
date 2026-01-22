output "namespace" {
  description = "Namespace where ActiveMQ is deployed"
  value       = var.enable_activemq ? kubernetes_namespace.activemq[0].metadata[0].name : null
} 