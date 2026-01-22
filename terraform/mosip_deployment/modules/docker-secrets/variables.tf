variable "docker_registry_url" {
  description = "Docker registry URL (e.g. https://index.docker.io/v1/ for dockerhub)"
  type        = string
  default     = "https://index.docker.io/v1/"
}

variable "docker_username" {
  description = "Docker registry username"
  type        = string
  default     = ""
}

variable "docker_password" {
  description = "Docker registry password/token"
  type        = string
  default     = ""
}

variable "docker_email" {
  description = "Docker registry email"
  type        = string
  default     = ""
}

variable "docker_secrets_enabled" {
  description = "Feature toggle for docker-secrets"
  type        = bool
  default     = false
} 