variable "namespace" {
  description = "Namespace for mosip-file-server"
  type        = string
  default     = "mosip-file-server"
}

variable "helm_chart_version" {
  description = "mosip-file-server Helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "helm_timeout_seconds" {
  description = "Timeout for mosip-file-server Helm operations"
  type        = number
  default     = 1200
}


