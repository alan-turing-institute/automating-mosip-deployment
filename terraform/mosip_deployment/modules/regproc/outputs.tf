output "namespace" {
  description = "The namespace where regproc is installed"
  value       = kubernetes_namespace.regproc.metadata[0].name
} 