variable "namespace" {
  description = "Namespace for artifactory deployment"
  type        = string
  default     = "artifactory"
}

variable "chart_version" {
  description = "Version of the artifactory Helm chart"
  type        = string
  default     = "12.0.2"  # Same version as in the shell script
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "startup_probe_timeout" {
  description = "Timeout seconds for startup probe"
  type        = number
  default     = 90
}

variable "startup_probe_initial_delay" {
  description = "Initial delay seconds for startup probe"
  type        = number
  default     = 90
} 