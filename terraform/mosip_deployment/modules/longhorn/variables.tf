variable "namespace" {
  description = "Namespace to deploy Longhorn"
  type        = string
  default     = "longhorn-system"
}

variable "chart_version" {
  description = "Version of the Longhorn Helm chart"
  type        = string
}

variable "replica_count" {
  description = "Number of replicas for Longhorn volumes"
  type        = number
  default     = 3
}

variable "guaranteed_engine_cpu" {
  description = "Guaranteed CPU for Longhorn engine"
  type        = string
  default     = "0.25"
}

variable "guaranteed_replica_cpu" {
  description = "Guaranteed CPU for Longhorn replica"
  type        = string
  default     = "0.25"
}

variable "storage_minimal_available_percentage" {
  description = "Minimal available percentage for storage"
  type        = number
  default     = 25
}

variable "storage_over_provisioning_percentage" {
  description = "Storage over-provisioning percentage"
  type        = number
  default     = 200
}

variable "storage_reserved_percentage" {
  description = "Storage reserved percentage"
  type        = number
  default     = 30
}

variable "auto_salvage" {
  description = "Enable auto salvage"
  type        = bool
  default     = true
}

variable "auto_delete_pod_when_volume_detached_unexpectedly" {
  description = "Auto delete pod when volume detached unexpectedly"
  type        = bool
  default     = true
}

variable "disable_scheduling_on_cordoned_node" {
  description = "Disable scheduling on cordoned node"
  type        = bool
  default     = true
}

variable "replica_zone_soft_anti_affinity" {
  description = "Enable replica zone soft anti-affinity"
  type        = bool
  default     = true
}

variable "storage_class_name" {
  description = "Name of the storage class"
  type        = string
  default     = "longhorn"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
} 