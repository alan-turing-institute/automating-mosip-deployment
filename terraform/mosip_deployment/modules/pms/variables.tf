variable "namespace" {
  description = "Namespace for pms"
  type        = string
  default     = "pms"
}

variable "helm_chart_version" {
  description = "PMS helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "pmp_ui_chart_version" {
  description = "PMP UI helm chart version"
  type        = string
  default     = "12.0.2"
}

variable "istio_injection_label" {
  description = "Istio injection label"
  type        = string
  default     = "enabled"  # As per original install.sh
}

variable "startup_probe_initial_delay" {
  description = "Initial delay for startup probe"
  type        = number
  default     = 90
}

variable "startup_probe_timeout" {
  description = "Timeout for startup probe"
  type        = number
  default     = 180
}

variable "helm_timeout_seconds" {
  description = "Timeout for helm operations"
  type        = number
  default     = 1200  # 20 minutes
} 