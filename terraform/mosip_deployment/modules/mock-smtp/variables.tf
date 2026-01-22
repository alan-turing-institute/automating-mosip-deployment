variable "helm_version" {
  type        = string
  description = "Helm chart version for mock-smtp"
  default     = "1.0.0"
}

variable "mock_smtp_host" {
  type        = string
  description = "SMTP host value"
} 