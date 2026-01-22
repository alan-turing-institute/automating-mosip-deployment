output "namespace" {
  description = "The namespace where msg-gateway resources are deployed"
  value       = kubernetes_namespace.msg_gateway[0].metadata[0].name
} 