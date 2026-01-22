variable "namespace" {
  description = "Namespace for MinIO deployment"
  type        = string
  default     = "minio"
}

variable "chart_version" {
  description = "Version of the MinIO Helm chart"
  type        = string
  default     = "10.1.6"  # Same version as in the shell script
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "enable_minio" {
  description = "Flag to enable/disable MinIO deployment"
  type        = bool
  default     = true
}

variable "enable_istio" {
  description = "Whether to enable Istio integration"
  type        = bool
  default     = true
}

variable "create_s3_namespace" {
  description = "Flag to create S3 namespace and credentials"
  type        = bool
  default     = false
}

variable "use_existing_minio" {
  description = "Use credentials from existing MinIO installation"
  type        = bool
  default     = true
}

variable "s3_user_key" {
  description = "S3 user key (only used if use_existing_minio is false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_user_secret" {
  description = "S3 user secret (only used if use_existing_minio is false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_region" {
  description = "S3 region (only used if use_existing_minio is false)"
  type        = string
  default     = ""
}

variable "s3_pretext_value" {
  description = "S3 pretext value for object store configuration"
  type        = string
  default     = ""
}

variable "bitnami_image_repository" {
  description = "Docker image repository prefix for Bitnami charts (e.g., 'bitnami', 'bitnamilegacy', or 'mosipid')"
  type        = string
  default     = "mosipid"
} 