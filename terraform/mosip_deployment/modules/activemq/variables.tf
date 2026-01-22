variable "enable_activemq" {
  description = "Whether to enable ActiveMQ deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace for ActiveMQ"
  type        = string
  default     = "activemq"
}

variable "helm_repo_url" {
  description = "MOSIP helm repository URL"
  type        = string
  default     = "https://mosip.github.io/mosip-helm"
}

variable "istio_enabled" {
  description = "Enable istio ingress"
  type        = bool
  default     = true
}

variable "ingress_controller" {
  description = "Name of the ingress controller"
  type        = string
  default     = "ingressgateway-internal"
}

variable "istio_prefix" {
  description = "Prefix for istio path"
  type        = string
  default     = "/"
} 