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