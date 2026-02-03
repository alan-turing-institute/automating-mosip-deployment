variable "namespace" {
  description = "Namespace for landing page"
  type        = string
  default     = "landing-page"
}

variable "chart_version" {
  description = "Landing page helm chart version"
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "landing_version" {
  description = "Landing page version"
  type        = string
}

variable "healthservices_host" {
  description = "Health Services host URL"
  type        = string
}

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1800
} 