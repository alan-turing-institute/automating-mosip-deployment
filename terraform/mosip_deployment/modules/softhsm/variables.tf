variable "namespace" {
  description = "Namespace for SoftHSM deployment"
  type        = string
  default     = "softhsm"
}

variable "chart_version" {
  description = "Version of the SoftHSM Helm chart"
  type        = string
  default     = "12.0.1"  # Same version as in the shell script
}

variable "enable_softhsm" {
  description = "Flag to enable/disable SoftHSM deployment"
  type        = bool
  default     = true
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
} 