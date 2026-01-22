variable "namespace" {
  description = "Namespace for prereg"
  type        = string
  default     = "prereg"
}

variable "helm_chart_version" {
  description = "Prereg helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "istio_injection_label" {
  description = "Istio injection label"
  type        = string
  default     = "disabled"  # As per original install.sh
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

variable "rate_limit_max_tokens" {
  description = "Maximum tokens for rate limiting"
  type        = number
  default     = 100
}

variable "rate_limit_tokens_per_fill" {
  description = "Tokens per fill for rate limiting"
  type        = number
  default     = 100
}

variable "rate_limit_fill_interval" {
  description = "Fill interval for rate limiting"
  type        = string
  default     = "50ms"
} 