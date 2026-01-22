variable "namespace" {
  description = "Namespace for Postgres deployment"
  type        = string
  default     = "postgres"
}

variable "chart_version" {
  description = "Version of the Postgres Helm chart"
  type        = string
  default     = "12.11.1"  # Same version as in the shell script
}

variable "init_chart_version" {
  description = "Version of the Postgres Init Helm chart"
  type        = string
  default     = "12.0.1"  # Same version as in init_db.sh
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

variable "bitnami_image_repository" {
  description = "Docker image repository prefix for Bitnami charts (e.g., 'bitnami', 'bitnamilegacy', or 'mosipid')"
  type        = string
  default     = "mosipid"
} 