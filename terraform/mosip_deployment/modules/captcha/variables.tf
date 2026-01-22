variable "namespace" {
  description = "Namespace for Captcha deployment"
  type        = string
  default     = "captcha"
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