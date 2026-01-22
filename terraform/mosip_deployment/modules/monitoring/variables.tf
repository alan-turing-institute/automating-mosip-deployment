variable "monitoring_namespace" {
  description = "Namespace for Rancher monitoring"
  type        = string
  default     = "cattle-monitoring-system"
}

variable "monitoring_crd_version" {
  description = "Version of Rancher monitoring CRD chart"
  type        = string
  default     = ""  # Empty means latest
}

variable "monitoring_version" {
  description = "Version of Rancher monitoring chart"
  type        = string
  default     = ""  # Empty means latest
} 