variable "helm_chart_version" {
  description = "Masterdata loader helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "mosip_data_github_branch" {
  description = "MOSIP data Github branch"
  type        = string
  default     = "v1.2.0.1"
}

variable "startup_probe_timeout" {
  description = "Timeout seconds for startup probe"
  type        = number
  default     = 180
}

variable "startup_probe_initial_delay" {
  description = "Initial delay seconds for startup probe"
  type        = number
  default     = 90
} 