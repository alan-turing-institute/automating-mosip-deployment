output "namespace" {
  description = "The namespace where captcha resources are deployed"
  value       = kubernetes_namespace_v1.captcha.metadata[0].name
}

output "secret_name" {
  description = "The name of the captcha secret"
  value       = kubernetes_secret_v1.mosip_captcha.metadata[0].name
} 