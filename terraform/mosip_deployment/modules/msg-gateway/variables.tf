variable "msg_gateway_enabled" {
  type        = bool
  description = "Enable or disable msg-gateway module"
  default     = true
}

variable "smtp_host" {
  type        = string
  description = "SMTP host address"
  default     = "mock-smtp.mock-smtp"
}

variable "sms_host" {
  type        = string
  description = "SMS host address"
  default     = "mock-smtp.mock-smtp"
}

variable "smtp_port" {
  type        = string
  description = "SMTP port"
  default     = "8025"
}

variable "sms_port" {
  type        = string
  description = "SMS port"
  default     = "8080"
}

variable "smtp_username" {
  type        = string
  description = "SMTP username"
  default     = ""
}

variable "sms_username" {
  type        = string
  description = "SMS username"
  default     = ""
}

variable "smtp_secret" {
  type        = string
  description = "SMTP secret"
  default     = "''"
}

variable "sms_secret" {
  type        = string
  description = "SMS secret"
  default     = "''"
}

variable "sms_authkey" {
  type        = string
  description = "SMS auth key"
  default     = "authkey"
} 