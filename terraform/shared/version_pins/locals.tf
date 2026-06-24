locals {
  profile_key = var.platform_version_profile

  # Grouped pins per stack — change profiles here when validating a new K8s line.
  profiles = {
    # MOSIP-aligned baseline: RKE2 v1.28.x + Rancher 2.8 + Istio 1.22
    k8s_1_28 = {
      rancher_version        = "2.8.3"
      ingress_nginx_version  = "4.10.0"
      longhorn_version       = "1.5.1"
      monitoring_crd_version = "103.1.1+up45.31.1"
      monitoring_version     = "103.1.0+up45.31.1"
      istio_version          = "1.22.0"
    }
    # Future stack: K8s 1.35 + Rancher 2.14 + Istio 1.30 (not yet tested end-to-end)
    k8s_1_35 = {
      rancher_version        = "2.14.2"
      ingress_nginx_version  = "4.15.1"
      longhorn_version       = "1.12.0"
      monitoring_crd_version = "109.0.1+up80.9.1-rancher.7"
      monitoring_version     = "109.0.1+up80.9.1-rancher.7"
      istio_version          = "1.30.0"
    }
  }

  selected = local.profiles[local.profile_key]

  rancher_version        = var.rancher_version != "" ? var.rancher_version : local.selected.rancher_version
  ingress_nginx_version  = var.ingress_nginx_version != "" ? var.ingress_nginx_version : local.selected.ingress_nginx_version
  longhorn_version       = var.longhorn_version != "" ? var.longhorn_version : local.selected.longhorn_version
  monitoring_crd_version = var.monitoring_crd_version != "" ? var.monitoring_crd_version : local.selected.monitoring_crd_version
  monitoring_version     = var.monitoring_version != "" ? var.monitoring_version : local.selected.monitoring_version
  istio_version          = var.istio_version != "" ? var.istio_version : local.selected.istio_version
}
