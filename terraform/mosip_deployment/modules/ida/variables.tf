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

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1800
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