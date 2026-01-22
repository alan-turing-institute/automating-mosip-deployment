variable "enable_clamav" {
  type        = bool
  description = "Feature flag for ClamAV deployment"
  default     = true
}

variable "helm_chart_version" {
  type        = string
  description = "ClamAV Helm chart version"
  default     = "2.4.1"
}

variable "replica_count" {
  type        = number
  description = "Number of ClamAV replicas"
  default     = 1
}

variable "image_repository" {
  type        = string
  description = "ClamAV image repository"
  default     = "clamav/clamav"
}

variable "image_tag" {
  type        = string
  description = "ClamAV image tag"
  default     = "latest"
}

variable "image_pull_policy" {
  type        = string
  description = "Image pull policy"
  default     = "Always"
} 