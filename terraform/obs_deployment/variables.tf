variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
}

variable "kubernetes_engine" {
  description = "Cluster engine: rke2 (default) or rke1 (legacy). Selects default chart pins when version overrides are empty."
  type        = string
  default     = "rke2"

  validation {
    condition     = contains(["rke2", "rke1"], var.kubernetes_engine)
    error_message = "kubernetes_engine must be rke2 or rke1."
  }
}

variable "ingress_nginx_namespace" {
  description = "Namespace for ingress-nginx"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_version" {
  description = "Version of ingress-nginx Helm chart (empty uses kubernetes_engine default)"
  type        = string
  default     = ""
}

variable "rancher_namespace" {
  description = "Namespace for Rancher"
  type        = string
  default     = "cattle-system"
}

variable "rancher_hostname" {
  description = "Hostname for Rancher UI"
  type        = string
}

variable "rancher_version" {
  description = "Version of Rancher Helm chart (empty uses kubernetes_engine default)"
  type        = string
  default     = ""
}

variable "rancher_replicas" {
  description = "Number of Rancher replicas"
  type        = number
  default     = 2
}

variable "rancher_bootstrap_password" {
  description = "Bootstrap password for Rancher"
  type        = string
  default     = "admin"
}

variable "longhorn_namespace" {
  description = "Namespace for Longhorn"
  type        = string
  default     = "longhorn-system"
}

variable "longhorn_version" {
  description = "Version of Longhorn Helm chart"
  type        = string
  default     = "1.4.2"
}

variable "filesystem_pv_size" {
  description = "Size of the filesystem PV"
  type        = string
  default     = "20Gi"
}

variable "ingress_nginx_values" {
  description = "Values for ingress-nginx Helm chart"
  type = object({
    controller = object({
      service = object({
        type = string
        nodePorts = object({
          http  = string
          https = string
        })
      })
      config = object({
        use_forwarded_headers = string
      })
    })
  })
  default = {
    controller = {
      service = {
        type = "NodePort"
        nodePorts = {
          http  = "30080"
          https = "30443"
        }
      }
      config = {
        use_forwarded_headers = "true"
      }
    }
  }
} 