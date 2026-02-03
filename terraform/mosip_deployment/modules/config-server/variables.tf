variable "namespace" {
  description = "Namespace for config-server deployment"
  type        = string
  default     = "config-server"
}

variable "chart_version" {
  description = "Helm chart version for config-server"
  type        = string
  default     = "12.0.1"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "enable_config_server" {
  description = "Flag to enable or disable config-server deployment"
  type        = bool
  default     = true
}

variable "git_repo_uri" {
  description = "Git repository URI for config server"
  type        = string
  default     = "https://github.com/mosip/mosip-config"
}

variable "git_repo_version" {
  description = "Git repository version/branch/tag for config server"
  type        = string
  default     = "v1.2.0.1"
}

variable "git_search_folders" {
  description = "Folders within the base repo where properties may be found"
  type        = string
  default     = ""
}

variable "git_private" {
  description = "Whether the Git repository is private"
  type        = bool
  default     = false
}

variable "git_username" {
  description = "Username for private Git repository access"
  type        = string
  default     = ""
}

variable "git_token" {
  description = "Token for private Git repository access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations in seconds. Should be longer than startup_probe_initial_delay + buffer"
  type        = number
  default     = 2400  # 40 minutes default (20 min startup + 20 min buffer)
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