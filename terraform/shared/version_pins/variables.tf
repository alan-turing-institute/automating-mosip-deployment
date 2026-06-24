variable "platform_version_profile" {
  description = "Version profile: k8s_1_28 (default tested baseline) or k8s_1_35 (future)."
  type        = string
  default     = "k8s_1_28"

  validation {
    condition     = contains(["k8s_1_28", "k8s_1_35"], var.platform_version_profile)
    error_message = "platform_version_profile must be k8s_1_28 or k8s_1_35."
  }
}

variable "rancher_version" {
  description = "Override Rancher Helm chart version (empty = profile default)."
  type        = string
  default     = ""
}

variable "ingress_nginx_version" {
  description = "Override ingress-nginx Helm chart version (empty = profile default)."
  type        = string
  default     = ""
}

variable "longhorn_version" {
  description = "Override Longhorn Helm chart version (empty = profile default)."
  type        = string
  default     = ""
}

variable "monitoring_crd_version" {
  description = "Override rancher-monitoring-crd chart version (empty = profile default)."
  type        = string
  default     = ""
}

variable "monitoring_version" {
  description = "Override rancher-monitoring chart version (empty = profile default)."
  type        = string
  default     = ""
}

variable "istio_version" {
  description = "Override Istio version for infra addons (empty = profile default)."
  type        = string
  default     = ""
}
