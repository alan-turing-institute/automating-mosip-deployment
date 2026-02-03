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

# CSI Component Configuration
variable "csi_attacher_replica_count" {
  description = "Number of replicas for CSI attacher (should be 1 to avoid leader election conflicts)"
  type        = number
  default     = 1
}

variable "csi_provisioner_replica_count" {
  description = "Number of replicas for CSI provisioner (1 for dev, 2-3 for production)"
  type        = number
  default     = 1
}

variable "csi_resizer_replica_count" {
  description = "Number of replicas for CSI resizer (1 for dev, 2 for production)"
  type        = number
  default     = 1
}

variable "csi_snapshotter_replica_count" {
  description = "Number of replicas for CSI snapshotter (1 for dev, 2 for production)"
  type        = number
  default     = 1
}

# CSI Attacher Resources
variable "csi_attacher_cpu_request" {
  description = "CPU request for CSI attacher"
  type        = string
  default     = "10m"
}

variable "csi_attacher_memory_request" {
  description = "Memory request for CSI attacher"
  type        = string
  default     = "32Mi"
}

variable "csi_attacher_cpu_limit" {
  description = "CPU limit for CSI attacher"
  type        = string
  default     = "100m"
}

variable "csi_attacher_memory_limit" {
  description = "Memory limit for CSI attacher"
  type        = string
  default     = "128Mi"
}

# CSI Provisioner Resources
variable "csi_provisioner_cpu_request" {
  description = "CPU request for CSI provisioner"
  type        = string
  default     = "10m"
}

variable "csi_provisioner_memory_request" {
  description = "Memory request for CSI provisioner"
  type        = string
  default     = "32Mi"
}

variable "csi_provisioner_cpu_limit" {
  description = "CPU limit for CSI provisioner"
  type        = string
  default     = "100m"
}

variable "csi_provisioner_memory_limit" {
  description = "Memory limit for CSI provisioner"
  type        = string
  default     = "128Mi"
}

# CSI Resizer Resources
variable "csi_resizer_cpu_request" {
  description = "CPU request for CSI resizer"
  type        = string
  default     = "10m"
}

variable "csi_resizer_memory_request" {
  description = "Memory request for CSI resizer"
  type        = string
  default     = "32Mi"
}

variable "csi_resizer_cpu_limit" {
  description = "CPU limit for CSI resizer"
  type        = string
  default     = "100m"
}

variable "csi_resizer_memory_limit" {
  description = "Memory limit for CSI resizer"
  type        = string
  default     = "128Mi"
}

# CSI Snapshotter Resources
variable "csi_snapshotter_cpu_request" {
  description = "CPU request for CSI snapshotter"
  type        = string
  default     = "10m"
}

variable "csi_snapshotter_memory_request" {
  description = "Memory request for CSI snapshotter"
  type        = string
  default     = "32Mi"
}

variable "csi_snapshotter_cpu_limit" {
  description = "CPU limit for CSI snapshotter"
  type        = string
  default     = "100m"
}

variable "csi_snapshotter_memory_limit" {
  description = "Memory limit for CSI snapshotter"
  type        = string
  default     = "128Mi"
}

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 1800
} 