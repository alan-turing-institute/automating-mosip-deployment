variable "namespace" {
  description = "Namespace for IAM deployment"
  type        = string
}

variable "chart_version" {
  description = "Version of the Keycloak Helm chart"
  type        = string
}

variable "init_chart_version" {
  description = "Version of the Keycloak init Helm chart"
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "admin_password" {
  description = "Initial admin password for Keycloak"
  type        = string
  sensitive   = true
}

variable "image_repository" {
  description = "Keycloak image repository"
  type        = string
}

variable "image_tag" {
  description = "Keycloak image tag"
  type        = string
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
}

variable "smtp_host" {
  description = "SMTP host for Keycloak email configuration"
  type        = string
}

variable "smtp_port" {
  description = "SMTP port for Keycloak email configuration"
  type        = string
}

variable "smtp_from" {
  description = "From email address for Keycloak emails"
  type        = string
}

variable "smtp_starttls" {
  description = "Enable STARTTLS for SMTP"
  type        = bool
}

variable "smtp_auth" {
  description = "Enable SMTP authentication"
  type        = bool
}

variable "smtp_ssl" {
  description = "Enable SSL for SMTP"
  type        = bool
}

variable "smtp_username" {
  description = "SMTP username if auth enabled"
  type        = string
}

variable "smtp_password" {
  description = "SMTP password if auth enabled"
  type        = string
  sensitive   = true
}

variable "enable_istio" {
  description = "Whether to enable Istio integration"
  type        = bool
  default     = true
}

variable "bitnami_image_repository" {
  description = "Docker image repository prefix for Bitnami charts (e.g., 'bitnami', 'bitnamilegacy', or 'mosipid')"
  type        = string
  default     = "mosipid"
} 