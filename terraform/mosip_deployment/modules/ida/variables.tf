variable "namespace" {
  description = "Namespace where ida will be installed"
  type        = string
  default     = "ida"
}

variable "helm_chart_version" {
  description = "Helm chart version for ida"
  type        = string
  default     = "12.0.1"
}

variable "enable_insecure" {
  description = "Flag to enable insecure mode for development environments"
  type        = bool
  default     = false
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1200
} 