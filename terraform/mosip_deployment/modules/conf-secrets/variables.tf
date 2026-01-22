variable "namespace" {
  description = "Namespace for conf-secrets"
  type        = string
  default     = "conf-secrets"
}

variable "enable" {
  description = "Enable or disable the module"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Helm chart version for conf-secrets"
  type        = string
  default     = "12.0.1"  # From original install.sh
}