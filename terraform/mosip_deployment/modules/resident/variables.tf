variable "namespace" {
  description = "Namespace for resident deployment"
  type        = string
  default     = "resident"
}

variable "helm_chart_version" {
  description = "Resident helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "ui_chart_version" {
  description = "Resident UI helm chart version"
  type        = string
  default     = "0.0.1"
}

variable "enable_insecure" {
  description = "Enable insecure mode for development environments"
  type        = bool
  default     = false
} 