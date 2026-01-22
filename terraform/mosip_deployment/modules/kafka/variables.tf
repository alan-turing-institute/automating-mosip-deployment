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