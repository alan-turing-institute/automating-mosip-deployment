variable "namespace" {
  description = "Namespace where regproc will be installed"
  type        = string
  default     = "regproc"
}

variable "helm_chart_version" {
  description = "Helm chart version for regproc"
  type        = string
  default     = "12.0.1"
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

# Regproc Group2-specific Probe Configuration Variables
variable "regproc_group2_startup_probe_enabled" {
  description = "Enable startup probe for regproc-group2"
  type        = bool
}

variable "regproc_group2_startup_probe_timeout_seconds" {
  description = "Timeout for startup probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_startup_probe_initial_delay_seconds" {
  description = "Initial delay for startup probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_startup_probe_period_seconds" {
  description = "Period for startup probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_startup_probe_failure_threshold" {
  description = "Failure threshold for startup probe for regproc-group2"
  type        = number
}

variable "regproc_group2_readiness_probe_enabled" {
  description = "Enable readiness probe for regproc-group2"
  type        = bool
}

variable "regproc_group2_readiness_probe_timeout_seconds" {
  description = "Timeout for readiness probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_readiness_probe_initial_delay_seconds" {
  description = "Initial delay for readiness probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_readiness_probe_period_seconds" {
  description = "Period for readiness probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_readiness_probe_failure_threshold" {
  description = "Failure threshold for readiness probe for regproc-group2"
  type        = number
}

variable "regproc_group2_liveness_probe_enabled" {
  description = "Enable liveness probe for regproc-group2"
  type        = bool
}

variable "regproc_group2_liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_liveness_probe_initial_delay_seconds" {
  description = "Initial delay for liveness probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_liveness_probe_period_seconds" {
  description = "Period for liveness probe in seconds for regproc-group2"
  type        = number
}

variable "regproc_group2_liveness_probe_failure_threshold" {
  description = "Failure threshold for liveness probe for regproc-group2"
  type        = number
}

# Regproc Notifier-specific Probe Configuration Variables
variable "regproc_notifier_startup_probe_enabled" {
  description = "Enable startup probe for regproc-notifier"
  type        = bool
}

variable "regproc_notifier_startup_probe_timeout_seconds" {
  description = "Timeout for startup probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_startup_probe_initial_delay_seconds" {
  description = "Initial delay for startup probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_startup_probe_period_seconds" {
  description = "Period for startup probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_startup_probe_failure_threshold" {
  description = "Failure threshold for startup probe for regproc-notifier"
  type        = number
}

variable "regproc_notifier_readiness_probe_enabled" {
  description = "Enable readiness probe for regproc-notifier"
  type        = bool
}

variable "regproc_notifier_readiness_probe_timeout_seconds" {
  description = "Timeout for readiness probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_readiness_probe_initial_delay_seconds" {
  description = "Initial delay for readiness probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_readiness_probe_period_seconds" {
  description = "Period for readiness probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_readiness_probe_failure_threshold" {
  description = "Failure threshold for readiness probe for regproc-notifier"
  type        = number
}

variable "regproc_notifier_liveness_probe_enabled" {
  description = "Enable liveness probe for regproc-notifier"
  type        = bool
}

variable "regproc_notifier_liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_liveness_probe_initial_delay_seconds" {
  description = "Initial delay for liveness probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_liveness_probe_period_seconds" {
  description = "Period for liveness probe in seconds for regproc-notifier"
  type        = number
}

variable "regproc_notifier_liveness_probe_failure_threshold" {
  description = "Failure threshold for liveness probe for regproc-notifier"
  type        = number
} 