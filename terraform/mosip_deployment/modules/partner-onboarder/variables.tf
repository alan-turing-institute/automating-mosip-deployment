variable "namespace" {
  description = "Namespace where partner-onboarder will be installed"
  type        = string
  default     = "onboarder"
}

variable "helm_chart_version" {
  description = "Helm chart version for partner-onboarder"
  type        = string
  default     = "12.0.1"
}

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1800
}

variable "s3_bucket_name" {
  description = "S3/MinIO bucket name for partner onboarder"
  type        = string
}

variable "s3_region" {
  description = "S3/MinIO region"
  type        = string
  default     = ""
}

variable "enable_insecure" {
  description = "Enable insecure mode for environments without valid SSL"
  type        = bool
  default     = false
}

variable "module_ida_enabled" {
  description = "Enable IDA module"
  type        = bool
  default     = true
}

variable "module_print_enabled" {
  description = "Enable Print module"
  type        = bool
  default     = true
}

variable "module_abis_enabled" {
  description = "Enable ABIS module"
  type        = bool
  default     = true
}

variable "module_resident_enabled" {
  description = "Enable Resident module"
  type        = bool
  default     = true
}

variable "module_mobileid_enabled" {
  description = "Enable Mobile ID module"
  type        = bool
  default     = true
}

variable "module_digitalcard_enabled" {
  description = "Enable Digital Card module"
  type        = bool
  default     = false
}

variable "module_esignet_enabled" {
  description = "Enable e-Signet module"
  type        = bool
  default     = false
}

variable "module_demo_oidc_enabled" {
  description = "Enable Demo OIDC module"
  type        = bool
  default     = false
}

variable "module_resident_oidc_enabled" {
  description = "Enable Resident OIDC module"
  type        = bool
  default     = false
}

variable "module_mimoto_keybinding_enabled" {
  description = "Enable Mimoto Keybinding module"
  type        = bool
  default     = true
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