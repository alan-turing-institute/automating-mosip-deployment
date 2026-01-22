output "namespace" {
  description = "The namespace where print is installed"
  value       = kubernetes_namespace.print.metadata[0].name
}

output "print_service_status" {
  description = "Status of print service deployment"
  value       = helm_release.print_service
} 