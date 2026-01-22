variable "namespace" {
  description = "Namespace for regclient deployment"
  type        = string
  default     = "regclient"
}

variable "helm_chart_version" {
  description = "Regclient helm chart version"
  type        = string
  default     = "12.0.2"
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