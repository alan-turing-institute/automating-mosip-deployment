variable "namespace" {
  description = "Namespace where regproc will be installed"
  type        = string
  default     = "regproc"
}

variable "helm_chart_version" {
  description = "Helm chart version for regproc"
  type        = string
  default     = "12.0.1"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1200
} 