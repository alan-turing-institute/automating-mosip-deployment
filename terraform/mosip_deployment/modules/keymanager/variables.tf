variable "namespace" {
  description = "Namespace for keymanager deployment"
  type        = string
  default     = "keymanager"
}

variable "chart_version" {
  description = "Version of the keymanager Helm chart"
  type        = string
  default     = "12.0.1"  # Same version as in the shell script
}

variable "keygen_chart_version" {
  description = "Version of the keygen Helm chart"
  type        = string
  default     = "12.0.1"  # Same version as in the shell script
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "enable_istio" {
  description = "Whether to enable Istio integration"
  type        = bool
  default     = true
}

variable "spring_config_name_env" {
  description = "Spring config name environment"
  type        = string
  default     = "kernel"
}

variable "softhsm_cm" {
  description = "SoftHSM ConfigMap name"
  type        = string
  default     = "softhsm-kernel-share"
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