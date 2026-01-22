variable "namespace" {
  description = "Namespace for mock services"
  type        = string
  default     = "abis"
}

variable "enable_mock_abis" {
  description = "Enable mock-abis deployment"
  type        = bool
  default     = true
}

variable "enable_mock_mv" {
  description = "Enable mock-mv deployment"
  type        = bool
  default     = true
}

variable "mock_abis_helm_chart_version" {
  description = "Mock-abis helm chart version"
  type        = string
  default     = "12.0.2"
}

variable "mock_mv_helm_chart_version" {
  description = "Mock-mv helm chart version"
  type        = string
  default     = "12.0.2"
}

variable "istio_injection_label" {
  description = "Istio injection label"
  type        = string
  default     = "enabled"  # As per original install.sh
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