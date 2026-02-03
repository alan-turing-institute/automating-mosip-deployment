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

variable "helm_timeout_seconds" {
  description = "Timeout for helm operations"
  type        = number
  default     = 1200  # 20 minutes
}

# Probe Configuration Variables
variable "startup_probe_enabled" {
  description = "Enable startup probe"
  type        = bool
}

variable "startup_probe_timeout_seconds" {
  description = "Timeout for startup probe in seconds"
  type        = number
}

variable "startup_probe_initial_delay_seconds" {
  description = "Initial delay for startup probe in seconds"
  type        = number
}

variable "startup_probe_period_seconds" {
  description = "Period for startup probe in seconds"
  type        = number
}

variable "startup_probe_failure_threshold" {
  description = "Failure threshold for startup probe"
  type        = number
}

variable "readiness_probe_enabled" {
  description = "Enable readiness probe"
  type        = bool
}

variable "readiness_probe_timeout_seconds" {
  description = "Timeout for readiness probe in seconds"
  type        = number
}

variable "readiness_probe_initial_delay_seconds" {
  description = "Initial delay for readiness probe in seconds"
  type        = number
}

variable "readiness_probe_period_seconds" {
  description = "Period for readiness probe in seconds"
  type        = number
}

variable "readiness_probe_failure_threshold" {
  description = "Failure threshold for readiness probe"
  type        = number
}

variable "liveness_probe_enabled" {
  description = "Enable liveness probe"
  type        = bool
}

variable "liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe in seconds"
  type        = number
}

variable "liveness_probe_initial_delay_seconds" {
  description = "Initial delay for liveness probe in seconds"
  type        = number
}

variable "liveness_probe_period_seconds" {
  description = "Period for liveness probe in seconds"
  type        = number
}

variable "liveness_probe_failure_threshold" {
  description = "Failure threshold for liveness probe"
  type        = number
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