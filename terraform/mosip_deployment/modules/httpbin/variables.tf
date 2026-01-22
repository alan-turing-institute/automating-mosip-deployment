variable "namespace" {
  description = "Namespace for httpbin deployment"
  type        = string
  default     = "httpbin"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
} 