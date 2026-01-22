terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.36.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

# Check prerequisites
resource "null_resource" "prerequisites" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/modules/scripts/check_prerequisites.sh ${var.kubeconfig_path}"
  }
}

# Provider configuration check
resource "null_resource" "provider_config" {
  depends_on = [null_resource.prerequisites]
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Deploy Longhorn
module "longhorn" {
  source = "./modules/longhorn"

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
  source = "./modules/monitoring"
  
  monitoring_namespace  = var.monitoring_namespace
  monitoring_crd_version = var.monitoring_crd_version
  monitoring_version    = var.monitoring_version

  depends_on = [module.longhorn]
}

# Global ConfigMap
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
    "mosip-resident-host"       = "resident.${var.installation_domain}"
    "mosip-compliance-host"     = "compliance.${var.installation_domain}"
    "mosip-esignet-host"        = "esignet.${var.installation_domain}"
    "mosip-smtp-host"           = "smtp.${var.installation_domain}"
    "mosip-signup-host"         = "signup.${var.installation_domain}"
    "is_glowroot_env"           = var.is_glowroot_env
  }

  depends_on = [module.longhorn]
}

# Deploy Istio Operator
module "istio" {
  source = "./modules/istio"
  
  enable_istio = var.enable_istio
  namespace = var.istio_namespace
  istio_version = var.istio_version
  proxy_protocol_enabled = var.proxy_protocol_enabled

  depends_on = [kubernetes_config_map_v1.global, module.longhorn, module.monitoring]
}

# Deploy httpbin
module "httpbin" {
  count  = var.httpbin_enable ? 1 : 0
  source = "./modules/httpbin"

  namespace       = var.httpbin_namespace
  kubeconfig_path = var.kubeconfig_path

  depends_on = [module.istio]
}

# Deploy Postgres
module "postgres" {
  count  = var.postgres_enable ? 1 : 0
  source = "./modules/postgres"

  namespace              = var.postgres_namespace
  chart_version          = var.postgres_version
  init_chart_version     = var.postgres_init_version
  kubeconfig_path        = var.kubeconfig_path
  bitnami_image_repository = var.bitnami_image_repository

  depends_on = [module.istio, module.longhorn, module.monitoring]
}

# Deploy IAM (Keycloak)
module "iam" {
  count  = var.iam_enable ? 1 : 0
  source = "./modules/iam"

  namespace          = var.iam_namespace
  chart_version      = var.iam_version
  init_chart_version = var.iam_init_version
  kubeconfig_path    = var.kubeconfig_path
  admin_password     = var.iam_admin_password

  # Image configuration
  image_repository   = var.iam_image_repository
  image_tag         = var.iam_image_tag
  image_pull_policy = var.iam_image_pull_policy

  # SMTP Configuration
  smtp_host         = var.iam_smtp_host
  smtp_port         = var.iam_smtp_port
  smtp_from         = var.iam_smtp_from
  smtp_starttls     = var.iam_smtp_starttls
  smtp_auth         = var.iam_smtp_auth
  smtp_ssl          = var.iam_smtp_ssl
  smtp_username     = var.iam_smtp_username
  smtp_password     = var.iam_smtp_password

  # Bitnami image repository configuration
  bitnami_image_repository = var.bitnami_image_repository

  depends_on = [module.postgres]
}

# Deploy SoftHSM
module "softhsm" {
  source          = "./modules/softhsm"
  kubeconfig_path = var.kubeconfig_path
  enable_softhsm  = var.enable_softhsm
  chart_version   = var.softhsm_chart_version
  depends_on      = [module.postgres, module.iam]
}

# Deploy MinIO
module "minio" {
  source = "./modules/minio"

  namespace       = var.minio_namespace
  kubeconfig_path = var.kubeconfig_path
  enable_minio    = var.enable_minio
  chart_version   = var.minio_chart_version
  
  # S3 Credential Management
  create_s3_namespace = var.create_s3_namespace
  use_existing_minio  = var.use_existing_minio
  s3_user_key         = var.s3_user_key
  s3_user_secret      = var.s3_user_secret
  s3_region           = var.s3_region
  s3_pretext_value    = var.s3_pretext_value

  # Bitnami image repository configuration
  bitnami_image_repository = var.bitnami_image_repository

  depends_on = [module.postgres, module.iam]
}

module "activemq" {
  count  = var.enable_activemq ? 1 : 0
  source = "./modules/activemq"

  enable_activemq = var.enable_activemq

  depends_on = [module.postgres, module.iam]
}

module "kafka" {
  count  = var.enable_kafka ? 1 : 0
  source = "./modules/kafka"

  kafka_ui_host           = "kafka.${var.installation_domain}"
  enable_deployment       = var.enable_kafka
  replica_count           = var.kafka_replica_count
  storage_size            = var.kafka_storage_size
  zookeeper_storage_size  = var.kafka_zookeeper_storage_size
  zookeeper_replica_count = var.kafka_zookeeper_replica_count
  bitnami_image_repository = var.bitnami_image_repository

  depends_on = [module.postgres, module.iam]
}

module "clamav" {
  count  = var.enable_clamav ? 1 : 0
  source = "./modules/clamav"
  
  enable_clamav     = var.enable_clamav
  helm_chart_version = var.clamav_helm_chart_version
  replica_count     = var.clamav_replica_count
  image_repository  = var.clamav_image_repository
  image_tag         = var.clamav_image_tag
  image_pull_policy = var.clamav_image_pull_policy

  depends_on = [module.postgres, module.iam]
}

module "msg_gateway" {
  count  = var.msg_gateway_enabled ? 1 : 0
  source = "./modules/msg-gateway"

  msg_gateway_enabled = var.msg_gateway_enabled
  smtp_host          = var.smtp_host
  sms_host           = var.sms_host
  smtp_port          = var.smtp_port
  sms_port           = var.sms_port
  smtp_username      = var.smtp_username
  sms_username       = var.sms_username
  smtp_secret        = var.smtp_secret
  sms_secret         = var.sms_secret
  sms_authkey        = var.sms_authkey

  depends_on = [module.postgres, module.iam]
}

module "docker_secrets" {
  count  = var.docker_secrets_enabled ? 1 : 0
  source = "./modules/docker-secrets"

  docker_secrets_enabled = var.docker_secrets_enabled
  docker_registry_url   = var.docker_registry_url
  docker_username       = var.docker_username
  docker_password       = var.docker_password
  docker_email         = var.docker_email

  depends_on = [module.postgres, module.iam]
}

module "conf_secrets" {
  count  = var.conf_secrets_enabled ? 1 : 0
  source = "./modules/conf-secrets"

  enable                     = var.conf_secrets_enabled
  namespace                  = var.conf_secrets_namespace
  chart_version             = var.conf_secrets_chart_version

  depends_on = [module.postgres, module.iam]
}


module "landing_page" {
  source = "./modules/landing-page"
  count  = var.enable_landing_page ? 1 : 0

  namespace          = "landing-page"
  chart_version      = var.landing_page_chart_version
  landing_version    = var.landing_version
  kubeconfig_path    = var.kubeconfig_path
  healthservices_host = var.healthservices_host

  depends_on = [module.postgres, module.iam]
}

module "captcha" {
  count  = var.enable_captcha ? 1 : 0
  source = "./modules/captcha"

  namespace = var.captcha_namespace
  kubeconfig_path = var.kubeconfig_path
  prereg_captcha_site_key = var.prereg_captcha_site_key
  prereg_captcha_secret_key = var.prereg_captcha_secret_key
  resident_captcha_site_key = var.resident_captcha_site_key
  resident_captcha_secret_key = var.resident_captcha_secret_key

  depends_on = [module.postgres, module.iam]
}

module "config_server" {
  count  = var.config_server_enabled ? 1 : 0
  source = "./modules/config-server"

  namespace          = var.config_server_namespace
  chart_version      = var.config_server_chart_version
  kubeconfig_path    = var.kubeconfig_path
  git_repo_uri       = var.config_server_git_repo_uri
  git_repo_version   = var.config_server_git_repo_version
  git_search_folders = var.config_server_git_search_folders
  git_private        = var.config_server_git_private
  git_username       = var.config_server_git_username
  git_token          = var.config_server_git_token

  depends_on = [kubernetes_config_map_v1.global, module.istio, module.longhorn, module.monitoring, module.postgres, module.iam, module.softhsm, module.minio, module.activemq, module.kafka, module.clamav, module.msg_gateway, module.docker_secrets, module.conf_secrets, module.landing_page, module.captcha]
}

# Deploy Artifactory
module "artifactory" {
  count  = var.artifactory_enable ? 1 : 0
  source = "./modules/artifactory"

  namespace                        = var.artifactory_namespace
  chart_version                   = var.artifactory_chart_version
  kubeconfig_path                 = var.kubeconfig_path
  startup_probe_timeout           = var.artifactory_startup_probe_timeout
  startup_probe_initial_delay     = var.artifactory_startup_probe_initial_delay

  depends_on = [module.config_server]
}

module "keymanager" {
  source = "./modules/keymanager"
  count  = var.enable_keymanager ? 1 : 0

  kubeconfig_path = var.kubeconfig_path
  enable_istio = var.enable_istio
  chart_version = var.keymanager_chart_version
  keygen_chart_version = var.keymanager_keygen_chart_version
  spring_config_name_env = var.keymanager_spring_config_name_env
  softhsm_cm = var.keymanager_softhsm_cm
  startup_probe_timeout = var.keymanager_startup_probe_timeout
  startup_probe_initial_delay = var.keymanager_startup_probe_initial_delay

  depends_on = [
    module.config_server,
    module.artifactory,
    module.softhsm
  ]
}

module "websub" {
  source = "./modules/websub"
  count  = var.websub_enabled ? 1 : 0

  helm_chart_version = var.websub_helm_chart_version
  startup_probe_timeout = var.websub_startup_probe_timeout
  startup_probe_initial_delay = var.websub_startup_probe_initial_delay

  depends_on = [
    module.keymanager
  ]
}

module "mock_smtp" {
  count  = var.mock_smtp_enabled ? 1 : 0
  source = "./modules/mock-smtp"

  mock_smtp_host    = var.mock_smtp_host
  helm_version = var.mock_smtp_helm_version

  depends_on = [
    module.keymanager
  ]
}

module "kernel" {
  count  = var.kernel_enabled ? 1 : 0
  source = "./modules/kernel"

  namespace                   = var.kernel_namespace
  helm_chart_version         = var.kernel_helm_chart_version
  enable_insecure            = var.kernel_enable_insecure
  startup_probe_timeout      = var.kernel_startup_probe_timeout
  startup_probe_initial_delay = var.kernel_startup_probe_initial_delay
  helm_timeout_seconds       = var.kernel_helm_timeout_seconds

  depends_on = [
    module.keymanager,
    module.mock_smtp,
    module.websub
  ]

}

module "masterdata_loader" {
  source = "./modules/masterdata-loader"
  count  = var.masterdata_loader_enabled ? 1 : 0

  helm_chart_version      = var.masterdata_loader_helm_chart_version
  mosip_data_github_branch = var.masterdata_loader_mosip_data_github_branch
  startup_probe_timeout = var.masterdata_loader_startup_probe_timeout
  startup_probe_initial_delay = var.masterdata_loader_startup_probe_initial_delay

  depends_on = [module.kernel]
}

module "biosdk" {
  source = "./modules/biosdk"
  count  = var.biosdk_enabled ? 1 : 0

  namespace                   = var.biosdk_namespace
  helm_chart_version         = var.biosdk_helm_chart_version
  istio_injection_label      = "enabled"
  startup_probe_timeout      = var.biosdk_startup_probe_timeout
  startup_probe_initial_delay = var.biosdk_startup_probe_initial_delay
  helm_timeout_seconds       = 1200  # 20 minutes

  depends_on = [module.kernel, module.masterdata_loader]
}

module "packetmanager" {
  source = "./modules/packetmanager"
  count  = var.packetmanager_enabled ? 1 : 0

  namespace                   = var.packetmanager_namespace
  helm_chart_version         = var.packetmanager_helm_chart_version
  istio_injection_label      = "enabled"
  startup_probe_timeout      = var.packetmanager_startup_probe_timeout
  startup_probe_initial_delay = var.packetmanager_startup_probe_initial_delay
  helm_timeout_seconds       = 1200  # 20 minutes

  depends_on = [module.kernel, module.biosdk]
}

module "datashare" {
  source = "./modules/datashare"
  count  = var.datashare_enabled ? 1 : 0

  namespace                   = var.datashare_namespace
  helm_chart_version         = var.datashare_helm_chart_version
  istio_injection_label      = "enabled"
  startup_probe_timeout      = var.datashare_startup_probe_timeout
  startup_probe_initial_delay = var.datashare_startup_probe_initial_delay
  helm_timeout_seconds       = 1200  # 20 minutes

  depends_on = [module.kernel, module.packetmanager]
}

module "prereg" {
  source = "./modules/prereg"
  count  = var.prereg_enabled ? 1 : 0

  namespace           = var.prereg_namespace
  helm_chart_version  = var.prereg_chart_version
  istio_injection_label = var.prereg_istio_injection_label
  startup_probe_timeout = var.prereg_startup_probe_timeout
  startup_probe_initial_delay = var.prereg_startup_probe_initial_delay
  helm_timeout_seconds = var.prereg_helm_timeout_seconds
  rate_limit_max_tokens = var.prereg_rate_limit_max_tokens
  rate_limit_tokens_per_fill = var.prereg_rate_limit_tokens_per_fill
  rate_limit_fill_interval = var.prereg_rate_limit_fill_interval

  depends_on = [module.kernel, module.datashare]
}
module "idrepo" {
  source = "./modules/idrepo"
  count  = var.idrepo_enabled ? 1 : 0

  namespace                   = var.idrepo_namespace
  helm_chart_version         = var.idrepo_helm_chart_version
  istio_injection_label      = var.idrepo_istio_injection_label
  startup_probe_timeout      = var.idrepo_startup_probe_timeout
  startup_probe_initial_delay = var.idrepo_startup_probe_initial_delay
  helm_timeout_seconds       = var.idrepo_helm_timeout_seconds

  depends_on = [module.kernel, module.prereg]
}

module "pms" {
  source = "./modules/pms"
  count  = var.pms_enabled ? 1 : 0

  namespace                   = var.pms_namespace
  helm_chart_version         = var.pms_helm_chart_version
  pmp_ui_chart_version       = var.pmp_ui_chart_version
  istio_injection_label      = var.pms_istio_injection_label
  startup_probe_timeout      = var.pms_startup_probe_timeout
  startup_probe_initial_delay = var.pms_startup_probe_initial_delay
  helm_timeout_seconds       = var.pms_helm_timeout_seconds

  depends_on = [module.kernel, module.idrepo]
}

module "mock_abis" {
  source = "./modules/mock-abis"
  count  = var.mock_abis_enabled || var.mock_mv_enabled ? 1 : 0

  namespace                    = var.mock_abis_namespace
  enable_mock_abis            = var.mock_abis_enabled
  enable_mock_mv              = var.mock_mv_enabled
  mock_abis_helm_chart_version = var.mock_abis_helm_chart_version
  mock_mv_helm_chart_version   = var.mock_mv_helm_chart_version
  istio_injection_label       = var.mock_abis_istio_injection_label
  startup_probe_timeout       = var.mock_abis_startup_probe_timeout
  startup_probe_initial_delay = var.mock_abis_startup_probe_initial_delay
  helm_timeout_seconds        = var.mock_abis_helm_timeout_seconds

  depends_on = [
    module.config_server,
    module.artifactory,
    module.keymanager,
    module.pms
  ]
}



module "regproc" {
  source = "./modules/regproc"
  count  = var.regproc_enabled ? 1 : 0

  namespace         = var.regproc_namespace
  helm_chart_version = var.regproc_helm_chart_version
  helm_timeout      = var.regproc_helm_timeout

  depends_on = [module.kernel, module.masterdata_loader,module.prereg, module.mock_abis]
}

module "admin" {
  source = "./modules/admin"
  count  = var.admin_enabled ? 1 : 0

  namespace         = var.admin_namespace
  helm_chart_version = var.admin_helm_chart_version
  helm_timeout      = var.admin_helm_timeout

  depends_on = [module.kernel, module.masterdata_loader,module.prereg, module.regproc]
}

module "ida" {
  source = "./modules/ida"
  count  = var.ida_enabled ? 1 : 0

  namespace         = var.ida_namespace
  helm_chart_version = var.ida_helm_chart_version
  enable_insecure   = var.ida_enable_insecure
  depends_on = [module.kernel,module.admin]
}

module "print" {
  source = "./modules/print"
  count  = var.print_enabled ? 1 : 0

  namespace         = var.print_namespace
  helm_chart_version = var.print_helm_chart_version
  depends_on = [module.kernel,module.admin,module.ida]
}

module "resident" {
  source = "./modules/resident"
  count  = var.resident_enabled ? 1 : 0

  namespace          = var.resident_namespace
  helm_chart_version = var.resident_helm_chart_version
  ui_chart_version   = var.resident_ui_chart_version
  enable_insecure    = var.resident_enable_insecure

  depends_on = [module.kernel,module.admin,module.regproc,module.print]
}

module "partner_onboarder" {
  source = "./modules/partner-onboarder"
  count  = var.partner_onboarder_enabled ? 1 : 0

  namespace         = var.partner_onboarder_namespace
  helm_chart_version = var.partner_onboarder_helm_chart_version
  s3_bucket_name    = var.partner_onboarder_s3_bucket_name
  depends_on = [module.kernel,module.admin,module.regproc,module.ida,module.print,module.resident]
}

module "regclient" {
  source = "./modules/regclient"
  count  = var.regclient_enabled ? 1 : 0

  namespace          = var.regclient_namespace
  helm_chart_version = var.regclient_helm_chart_version
  startup_probe_timeout = var.regclient_startup_probe_timeout
  startup_probe_initial_delay = var.regclient_startup_probe_initial_delay

  depends_on = [module.kernel,module.admin,module.regproc]
}

module "mosip_file_server" {
  source = "./modules/mosip-file-server"
  count  = var.mosip_file_server_enabled ? 1 : 0

  namespace           = var.mosip_file_server_namespace
  helm_chart_version  = var.mosip_file_server_helm_chart_version
  helm_timeout_seconds = var.mosip_file_server_helm_timeout

  depends_on = [
    module.kernel,
    module.admin,
    module.regproc
  ]
}
