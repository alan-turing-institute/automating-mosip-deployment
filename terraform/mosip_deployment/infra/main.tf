# Check prerequisites
resource "null_resource" "prerequisites" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/../modules/scripts/check_prerequisites.sh ${var.kubeconfig_path}"
  }
}

# Provider configuration check
resource "null_resource" "provider_config" {
  depends_on = [null_resource.prerequisites]
}

# ============================================================================
# INFRASTRUCTURE DEPLOYMENT
# ============================================================================
# This deploys the foundational infrastructure that MOSIP services depend on:
# - Longhorn (storage)
# - Monitoring (Prometheus CRDs)
# - Global ConfigMap (foundation for all services)
# - Istio (service mesh + CRDs)
# ============================================================================

# Deploy Longhorn
module "longhorn" {
  count  = var.longhorn_enable ? 1 : 0
  source = "../modules/longhorn"

  namespace                                          = var.longhorn_namespace
  chart_version                                     = var.longhorn_version
  replica_count                                     = var.longhorn_replica_count
  guaranteed_engine_cpu                             = var.longhorn_guaranteed_engine_cpu
  guaranteed_replica_cpu                            = var.longhorn_guaranteed_replica_cpu
  storage_minimal_available_percentage              = var.longhorn_storage_minimal_available_percentage
  storage_over_provisioning_percentage              = var.longhorn_storage_over_provisioning_percentage
  storage_reserved_percentage                       = var.longhorn_storage_reserved_percentage
  auto_salvage                                      = var.longhorn_auto_salvage
  auto_delete_pod_when_volume_detached_unexpectedly = var.longhorn_auto_delete_pod_when_volume_detached_unexpectedly
  disable_scheduling_on_cordoned_node               = var.longhorn_disable_scheduling_on_cordoned_node
  replica_zone_soft_anti_affinity                   = var.longhorn_replica_zone_soft_anti_affinity
  storage_class_name                                = var.longhorn_storage_class_name
  kubeconfig_path                                   = var.kubeconfig_path

  depends_on = [null_resource.provider_config]
}

# Deploy Monitoring
module "monitoring" {
  source = "../modules/monitoring"
  
  monitoring_namespace   = var.monitoring_namespace
  monitoring_crd_version = var.monitoring_crd_version
  monitoring_version     = var.monitoring_version

  depends_on = [null_resource.provider_config, module.longhorn]
}

# Global ConfigMap - Foundation for all services
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }

  data = {
    "installation-name"          = var.installation_name
    "installation-domain"        = var.installation_domain
    "mosip-version"             = var.mosip_version
    "mosip-api-host"            = "api.${var.installation_domain}"
    "mosip-api-internal-host"   = "api-internal.${var.installation_domain}"
    "mosip-prereg-host"         = "prereg.${var.installation_domain}"
    "mosip-activemq-host"       = "activemq.${var.installation_domain}"
    "mosip-kibana-host"         = "kibana.${var.installation_domain}"
    "mosip-admin-host"          = "admin.${var.installation_domain}"
    "mosip-regclient-host"      = "regclient.${var.installation_domain}"
    "mosip-minio-host"          = "minio.${var.installation_domain}"
    "mosip-kafka-host"          = "kafka.${var.installation_domain}"
    "mosip-iam-external-host"   = "iam.${var.installation_domain}"
    "mosip-postgres-host"       = "postgres.${var.installation_domain}"
    "mosip-pmp-host"            = "pmp.${var.installation_domain}"
    "mosip-pmp-revamp-ui-host"  = "pmp-revamp.${var.installation_domain}"
    "mosip-resident-host"       = "resident.${var.installation_domain}"
    "mosip-compliance-host"     = "compliance.${var.installation_domain}"
    "mosip-esignet-host"        = "esignet.${var.installation_domain}"
    "mosip-smtp-host"           = "smtp.${var.installation_domain}"
    "mosip-signup-host"         = "signup.${var.installation_domain}"
    "is_glowroot_env"           = var.is_glowroot_env
  }

  depends_on = [null_resource.provider_config, module.longhorn]
}

# Deploy Istio Operator - This creates the CRDs that MOSIP services need
module "istio" {
  source = "../modules/istio"
  
  enable_istio = var.enable_istio
  namespace = var.istio_namespace
  istio_version = var.istio_version
  proxy_protocol_enabled = var.proxy_protocol_enabled

  depends_on = [kubernetes_config_map_v1.global, module.monitoring]
}
