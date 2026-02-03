variable "helm_release_name" {
  description = "Helm release name for Kafka"
  type        = string
  default     = "kafka"
}

variable "namespace" {
  description = "Namespace for Kafka deployment"
  type        = string
  default     = "kafka"
}

variable "kafka_ui_host" {
  description = "Hostname for Kafka UI"
  type        = string
}

variable "kafka_chart_version" {
  description = "Version of the Kafka Helm chart"
  type        = string
  default     = "18.3.1"
}

variable "kafka_ui_chart_version" {
  description = "Version of the Kafka UI Helm chart"
  type        = string
  default     = "0.4.2"
}

variable "replica_count" {
  description = "Number of Kafka replicas"
  type        = number
  default     = 5
}

variable "zookeeper_replica_count" {
  description = "Number of Zookeeper replicas"
  type        = number
  default     = 5
}

variable "enable_deployment" {
  description = "Flag to enable/disable Kafka deployment"
  type        = bool
  default     = true
}

variable "storage_size" {
  description = "Storage size for Kafka PVC"
  type        = string
  default     = "8Gi"
}

variable "zookeeper_storage_size" {
  description = "Storage size for Zookeeper PVC"
  type        = string
  default     = "2Gi"
}

variable "bitnami_image_repository" {
  description = "Docker image repository prefix for Bitnami charts (e.g., 'bitnami', 'bitnamilegacy', or 'mosipid')"
  type        = string
  default     = "mosipid"
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