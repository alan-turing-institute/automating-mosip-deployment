variable "namespace" {
  description = "Namespace for Captcha deployment"
  type        = string
  default     = "captcha"
}

variable "helm_chart_version" {
  description = "Helm chart version for captcha"
  type        = string
}

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600
}

variable "metrics_service_monitor_enabled" {
  description = "Enable Prometheus ServiceMonitor for captcha"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "prereg_captcha_site_key" {
  description = "Recaptcha admin site key for PreReg domain"
  type        = string
  default     = ""
}

variable "prereg_captcha_secret_key" {
  description = "Recaptcha admin secret key for PreReg domain"
  type        = string
  default     = ""
}

variable "resident_captcha_site_key" {
  description = "Recaptcha admin site key for Resident domain"
  type        = string
  default     = ""
}

variable "resident_captcha_secret_key" {
  description = "Recaptcha admin secret key for Resident domain"
  type        = string
  default     = ""
} 