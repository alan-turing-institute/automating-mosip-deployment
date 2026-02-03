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

# Startup Probe Configuration
variable "startup_probe_enabled" {
  description = "Enable startup probe"
  type        = bool
}

variable "startup_probe_timeout_seconds" {
  description = "Timeout for startup probe in seconds"
  type        = number
}

variable "startup_probe_initial_delay_seconds" {
  description = "Initial delay for startup probe in seconds"
  type        = number
}

variable "startup_probe_period_seconds" {
  description = "Period for startup probe in seconds"
  type        = number
}

variable "startup_probe_failure_threshold" {
  description = "Failure threshold for startup probe"
  type        = number
}

# Readiness Probe Configuration
variable "readiness_probe_enabled" {
  description = "Enable readiness probe"
  type        = bool
}

variable "readiness_probe_timeout_seconds" {
  description = "Timeout for readiness probe in seconds"
  type        = number
}

variable "readiness_probe_initial_delay_seconds" {
  description = "Initial delay for readiness probe in seconds"
  type        = number
}

variable "readiness_probe_period_seconds" {
  description = "Period for readiness probe in seconds"
  type        = number
}

variable "readiness_probe_failure_threshold" {
  description = "Failure threshold for readiness probe"
  type        = number
}

# Liveness Probe Configuration
variable "liveness_probe_enabled" {
  description = "Enable liveness probe"
  type        = bool
}

variable "liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe in seconds"
  type        = number
}

variable "liveness_probe_initial_delay_seconds" {
  description = "Initial delay for liveness probe in seconds"
  type        = number
}

variable "liveness_probe_period_seconds" {
  description = "Period for liveness probe in seconds"
  type        = number
}

variable "liveness_probe_failure_threshold" {
  description = "Failure threshold for liveness probe"
  type        = number
} 