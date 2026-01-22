variable "namespace" {
  description = "Namespace where print will be installed"
  type        = string
  default     = "print"
}

variable "helm_chart_version" {
  description = "Helm chart version for print"
  type        = string
  default     = "12.0.1"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1200
} 