variable "namespace" {
  description = "Namespace for packetmanager"
  type        = string
  default     = "packetmanager"
}

variable "helm_chart_version" {
  description = "Packetmanager helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "istio_injection_label" {
  description = "Istio injection label"
  type        = string
  default     = "enabled"
}

variable "startup_probe_initial_delay" {
  description = "Initial delay for startup probe"
  type        = number
  default     = 90
}

variable "startup_probe_timeout" {
  description = "Timeout for startup probe"
  type        = number
  default     = 180
}

variable "helm_timeout_seconds" {
  description = "Timeout for helm operations"
  type        = number
  default     = 1200  # 20 minutes
} 