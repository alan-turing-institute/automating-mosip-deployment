variable "namespace" {
  description = "Namespace where admin will be installed"
  type        = string
  default     = "admin"
}

variable "helm_chart_version" {
  description = "Helm chart version for admin"
  type        = string
  default     = "12.0.1"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1200
} 