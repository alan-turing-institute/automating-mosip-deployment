# Infrastructure Variables
# These variables are used for infrastructure deployment (Longhorn, Monitoring, Istio)

variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig file"
}

variable "kubernetes_engine" {
  type        = string
  description = "Cluster engine: rke2 (default) or rke1 (legacy). Selects default infra chart pins."
  default     = "rke2"

  validation {
    condition     = contains(["rke2", "rke1"], var.kubernetes_engine)
    error_message = "kubernetes_engine must be rke2 or rke1."
  }
}

variable "installation_name" {
  type        = string
  description = "Name of the MOSIP installation"
}

variable "installation_domain" {
  type        = string
  description = "Domain name for the MOSIP installation"
}

variable "mosip_version" {
  type        = string
  description = "MOSIP version to deploy"
}

variable "is_glowroot_env" {
  type        = string
  description = "Whether to enable Glowroot for Java profiling"
  default     = "absent"
}

# Longhorn Variables
variable "longhorn_enable" {
  type        = bool
  description = "Whether to enable Longhorn deployment"
  default     = true
}

variable "longhorn_namespace" {
  description = "Namespace to deploy Longhorn"
  type        = string
  default     = "longhorn-system"
}

variable "longhorn_version" {
  description = "Version of Longhorn to deploy"
  type        = string
}

variable "longhorn_replica_count" {
  description = "Number of replicas for Longhorn volumes"
  type        = number
  default     = 1
}

variable "longhorn_guaranteed_engine_cpu" {
  description = "Guaranteed CPU for engine manager"
  type        = string
  default     = "5"
}

variable "longhorn_guaranteed_replica_cpu" {
  description = "Guaranteed CPU for replica manager"
  type        = string
  default     = "5"
}

variable "longhorn_storage_minimal_available_percentage" {
  description = "Minimal available percentage for storage"
  type        = string
  default     = "25"
}

variable "longhorn_storage_over_provisioning_percentage" {
  description = "Storage over-provisioning percentage"
  type        = string
  default     = "200"
}

variable "longhorn_storage_reserved_percentage" {
  description = "Reserved storage percentage"
  type        = string
  default     = "25"
}

variable "longhorn_auto_salvage" {
  description = "Enable auto salvage"
  type        = string
  default     = "true"
}

variable "longhorn_auto_delete_pod_when_volume_detached_unexpectedly" {
  description = "Auto delete pod when volume detached"
  type        = string
  default     = "true"
}

variable "longhorn_disable_scheduling_on_cordoned_node" {
  description = "Disable scheduling on cordoned nodes"
  type        = string
  default     = "true"
}

variable "longhorn_replica_zone_soft_anti_affinity" {
  description = "Enable replica zone soft anti-affinity"
  type        = string
  default     = "true"
}

variable "longhorn_storage_class_name" {
  description = "Name of the storage class"
  type        = string
  default     = "longhorn"
}

# Monitoring Variables
variable "monitoring_namespace" {
  description = "Namespace for Rancher monitoring"
  type        = string
  default     = "cattle-monitoring-system"
}

variable "monitoring_crd_version" {
  description = "Version of Rancher monitoring CRD chart"
  type        = string
  default     = ""
}

variable "monitoring_version" {
  description = "Version of Rancher monitoring chart"
  type        = string
  default     = ""
}

# Istio Variables
variable "enable_istio" {
  type        = bool
  description = "Whether to enable Istio service mesh"
  default     = true
}

variable "istio_version" {
  type        = string
  description = "Version of Istio to install"
  default     = "1.22.0"
}

variable "istio_namespace" {
  type        = string
  description = "Namespace for Istio components"
  default     = "istio-system"
}

variable "proxy_protocol_enabled" {
  type        = bool
  description = "Enable proxy protocol for Istio ingress gateway"
  default     = false
}
