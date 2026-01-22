variable "namespace" {
  description = "Namespace for Istio components"
  type        = string
  default     = "istio-system"
}

variable "enable_istio" {
  description = "Whether to enable Istio installation"
  type        = bool
  default     = true
}

variable "istio_version" {
  description = "Version of Istio to install"
  type        = string
  default     = "1.15.0"
}

variable "proxy_protocol_enabled" {
  description = "Whether to enable proxy protocol for Istio gateways"
  type        = bool
  default     = false
} 