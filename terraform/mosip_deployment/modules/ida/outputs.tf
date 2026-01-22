output "namespace" {
  description = "The namespace where ida is installed"
  value       = kubernetes_namespace.ida.metadata[0].name
} 