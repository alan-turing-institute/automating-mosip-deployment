output "profile_key" {
  description = "Resolved platform version profile key."
  value       = local.profile_key
}

output "rancher_version" {
  value = local.rancher_version
}

output "ingress_nginx_version" {
  value = local.ingress_nginx_version
}

output "longhorn_version" {
  value = local.longhorn_version
}

output "monitoring_crd_version" {
  value = local.monitoring_crd_version
}

output "monitoring_version" {
  value = local.monitoring_version
}

output "istio_version" {
  value = local.istio_version
}
