variable "namespace" {
  description = "Namespace for kernel deployment"
  type        = string
  default     = "kernel"
}

variable "helm_chart_version" {
  description = "Helm chart version for kernel components"
  type        = string
  default     = "12.0.1"
}

variable "enable_insecure" {
  description = "Enable insecure mode for components that support it"
  type        = bool
  default     = false
}

variable "startup_probe_timeout" {
  description = "Timeout for startup probe"
  type        = number
  default     = 180
}

variable "startup_probe_initial_delay" {
  description = "Initial delay for startup probe"
  type        = number
  default     = 90
}

variable "helm_timeout_seconds" {
  description = "Timeout for helm operations"
  type        = number
  default     = 1200  # 20 minutes
} 