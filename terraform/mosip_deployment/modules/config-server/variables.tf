variable "namespace" {
  description = "Namespace for config-server deployment"
  type        = string
  default     = "config-server"
}

variable "chart_version" {
  description = "Helm chart version for config-server"
  type        = string
  default     = "12.0.1"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "enable_config_server" {
  description = "Flag to enable or disable config-server deployment"
  type        = bool
  default     = true
}

variable "git_repo_uri" {
  description = "Git repository URI for config server"
  type        = string
  default     = "https://github.com/mosip/mosip-config"
}

variable "git_repo_version" {
  description = "Git repository version/branch/tag for config server"
  type        = string
  default     = "v1.2.0.1"
}

variable "git_search_folders" {
  description = "Folders within the base repo where properties may be found"
  type        = string
  default     = ""
}

variable "git_private" {
  description = "Whether the Git repository is private"
  type        = bool
  default     = false
}

variable "git_username" {
  description = "Username for private Git repository access"
  type        = string
  default     = ""
}

variable "git_token" {
  description = "Token for private Git repository access"
  type        = string
  default     = ""
  sensitive   = true
} 