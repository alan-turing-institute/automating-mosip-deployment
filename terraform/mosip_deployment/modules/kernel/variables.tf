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

variable "helm_timeout_seconds" {
  description = "Timeout for helm operations"
  type        = number
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

# IDGenerator-specific Probe Configuration Variables
variable "idgenerator_startup_probe_enabled" {
  description = "Enable startup probe for idgenerator"
  type        = bool
}

variable "idgenerator_startup_probe_timeout_seconds" {
  description = "Timeout for startup probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_startup_probe_initial_delay_seconds" {
  description = "Initial delay for startup probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_startup_probe_period_seconds" {
  description = "Period for startup probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_startup_probe_failure_threshold" {
  description = "Failure threshold for startup probe for idgenerator"
  type        = number
}

variable "idgenerator_readiness_probe_enabled" {
  description = "Enable readiness probe for idgenerator"
  type        = bool
}

variable "idgenerator_readiness_probe_timeout_seconds" {
  description = "Timeout for readiness probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_readiness_probe_initial_delay_seconds" {
  description = "Initial delay for readiness probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_readiness_probe_period_seconds" {
  description = "Period for readiness probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_readiness_probe_failure_threshold" {
  description = "Failure threshold for readiness probe for idgenerator"
  type        = number
}

variable "idgenerator_liveness_probe_enabled" {
  description = "Enable liveness probe for idgenerator"
  type        = bool
}

variable "idgenerator_liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_liveness_probe_initial_delay_seconds" {
  description = "Initial delay for liveness probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_liveness_probe_period_seconds" {
  description = "Period for liveness probe in seconds for idgenerator"
  type        = number
}

variable "idgenerator_liveness_probe_failure_threshold" {
  description = "Failure threshold for liveness probe for idgenerator"
  type        = number
} 