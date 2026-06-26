locals {
  installation_domain        = data.kubernetes_config_map_v1.global.data["installation-domain"]
}

# Verify infrastructure prerequisites exist
# These data sources will fail during plan if infrastructure is not deployed
# This ensures proper deployment order

# ============================================================================
# DEPLOYMENT PHASES
# ============================================================================
# Modules are organized into sequential phases with time_sleep resources
# between phases to enforce ordering. This simplifies dependency computation
# and makes plan generation much faster.
# ============================================================================

# ============================================================================
# PHASE 1: External Services (Postgres, IAM, httpbin)
# ============================================================================

# Deploy httpbin
module "httpbin" {
  count  = var.httpbin_enable ? 1 : 0
  source = "../modules/httpbin"

  namespace       = var.httpbin_namespace
  kubeconfig_path = var.kubeconfig_path

  depends_on = [data.kubernetes_namespace.istio_system]
}

# Deploy Postgres
module "postgres" {
  count  = var.postgres_enable ? 1 : 0
  source = "../modules/postgres"

  namespace              = var.postgres_namespace
  chart_version          = var.postgres_version
  init_chart_version     = var.postgres_init_version
  kubeconfig_path        = var.kubeconfig_path
  bitnami_image_repository = var.bitnami_image_repository
  enable_istio           = var.enable_istio
  helm_timeout_seconds   = var.global_helm_timeout_seconds

  depends_on = [data.kubernetes_namespace.istio_system]
}

# Deploy IAM (Keycloak)
module "iam" {
  count  = var.iam_enable ? 1 : 0
  source = "../modules/iam"

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
  enable_istio            = var.enable_istio
  helm_timeout_seconds    = var.global_helm_timeout_seconds

  depends_on = [module.postgres]
}

# Wait for Phase 1 completion
resource "time_sleep" "phase_1_complete" {
  depends_on = [module.postgres, module.iam, module.httpbin]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 2: Supporting Services (can deploy in parallel)
# ============================================================================

# Deploy SoftHSM
module "softhsm" {
  source          = "../modules/softhsm"
  kubeconfig_path = var.kubeconfig_path
  enable_softhsm  = var.enable_softhsm
  chart_version   = var.softhsm_chart_version
  depends_on      = [time_sleep.phase_1_complete]
}

# Deploy MinIO
module "minio" {
  source = "../modules/minio"

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
  image_tag                = var.minio_image_tag
  enable_istio             = var.enable_istio

  depends_on = [time_sleep.phase_1_complete]
}

module "activemq" {
  count  = var.enable_activemq ? 1 : 0
  source = "../modules/activemq"

  enable_activemq = var.enable_activemq

  # Startup Probe Configuration
  startup_probe_enabled                = var.activemq_startup_probe_enabled
  startup_probe_timeout_seconds        = var.activemq_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.activemq_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.activemq_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.activemq_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.activemq_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.activemq_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.activemq_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.activemq_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.activemq_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.activemq_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.activemq_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.activemq_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.activemq_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.activemq_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_1_complete]
}

module "kafka" {
  count  = var.enable_kafka ? 1 : 0
  source = "../modules/kafka"

  kafka_ui_host           = "kafka.${local.installation_domain}"
  enable_deployment       = var.enable_kafka
  replica_count           = var.kafka_replica_count
  storage_size            = var.kafka_storage_size
  zookeeper_storage_size  = var.kafka_zookeeper_storage_size
  zookeeper_replica_count = var.kafka_zookeeper_replica_count
  bitnami_image_repository = var.bitnami_image_repository
  helm_timeout_seconds    = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.kafka_startup_probe_enabled
  startup_probe_timeout_seconds        = var.kafka_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.kafka_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.kafka_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.kafka_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.kafka_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.kafka_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.kafka_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.kafka_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.kafka_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.kafka_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.kafka_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.kafka_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.kafka_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.kafka_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_1_complete]
}

module "clamav" {
  count  = var.enable_clamav ? 1 : 0
  source = "../modules/clamav"
  
  enable_clamav     = var.enable_clamav
  helm_chart_version = var.clamav_helm_chart_version
  replica_count     = var.clamav_replica_count
  image_repository  = var.clamav_image_repository
  image_tag         = var.clamav_image_tag
  image_pull_policy = var.clamav_image_pull_policy
  helm_timeout_seconds = var.global_helm_timeout_seconds

  depends_on = [time_sleep.phase_1_complete]
}

module "msg_gateway" {
  count  = var.msg_gateway_enabled ? 1 : 0
  source = "../modules/msg-gateway"

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

  depends_on = [time_sleep.phase_1_complete]
}

module "docker_secrets" {
  count  = var.docker_secrets_enabled ? 1 : 0
  source = "../modules/docker-secrets"

  docker_secrets_enabled = var.docker_secrets_enabled
  docker_registry_url   = var.docker_registry_url
  docker_username       = var.docker_username
  docker_password       = var.docker_password
  docker_email         = var.docker_email

  depends_on = [time_sleep.phase_1_complete]
}

module "conf_secrets" {
  count  = var.conf_secrets_enabled ? 1 : 0
  source = "../modules/conf-secrets"

  enable                     = var.conf_secrets_enabled
  namespace                  = var.conf_secrets_namespace
  chart_version             = var.conf_secrets_chart_version
  helm_timeout_seconds      = var.global_helm_timeout_seconds

  depends_on = [time_sleep.phase_1_complete]
}

module "landing_page" {
  source = "../modules/landing-page"
  count  = var.enable_landing_page ? 1 : 0

  namespace          = "landing-page"
  chart_version      = var.landing_page_chart_version
  landing_version    = var.landing_version
  kubeconfig_path    = var.kubeconfig_path
  healthservices_host = var.healthservices_host
  helm_timeout_seconds = var.global_helm_timeout_seconds

  depends_on = [time_sleep.phase_1_complete]
}

module "captcha" {
  count  = var.enable_captcha ? 1 : 0
  source = "../modules/captcha"

  namespace = var.captcha_namespace
  kubeconfig_path = var.kubeconfig_path
  prereg_captcha_site_key = var.prereg_captcha_site_key
  prereg_captcha_secret_key = var.prereg_captcha_secret_key
  resident_captcha_site_key = var.resident_captcha_site_key
  resident_captcha_secret_key = var.resident_captcha_secret_key

  depends_on = [time_sleep.phase_1_complete]
}

# Wait for Phase 2 completion
resource "time_sleep" "phase_2_complete" {
  depends_on = [
    module.softhsm,
    module.minio,
    module.activemq,
    module.kafka,
    module.clamav,
    module.msg_gateway,
    module.docker_secrets,
    module.conf_secrets,
    module.landing_page,
    module.captcha
  ]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 3: Configuration Management
# ============================================================================

module "config_server" {
  count  = var.config_server_enabled ? 1 : 0
  source = "../modules/config-server"

  namespace          = var.config_server_namespace
  chart_version      = var.config_server_chart_version
  kubeconfig_path    = var.kubeconfig_path
  git_repo_uri       = var.config_server_git_repo_uri
  git_repo_version   = var.config_server_git_repo_version
  git_search_folders = var.config_server_git_search_folders
  git_private        = var.config_server_git_private
  git_username       = var.config_server_git_username
  git_token          = var.config_server_git_token
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.config_server_startup_probe_enabled
  startup_probe_timeout_seconds        = var.config_server_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.config_server_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.config_server_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.config_server_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.config_server_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.config_server_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.config_server_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.config_server_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.config_server_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.config_server_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.config_server_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.config_server_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.config_server_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.config_server_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_2_complete]
}

# Deploy Artifactory
module "artifactory" {
  count  = var.artifactory_enable ? 1 : 0
  source = "../modules/artifactory"

  namespace                        = var.artifactory_namespace
  chart_version                   = var.artifactory_chart_version
  kubeconfig_path                 = var.kubeconfig_path

  # Startup Probe Configuration
  startup_probe_enabled                = var.artifactory_startup_probe_enabled
  startup_probe_timeout_seconds        = var.artifactory_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.artifactory_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.artifactory_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.artifactory_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.artifactory_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.artifactory_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.artifactory_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.artifactory_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.artifactory_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.artifactory_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.artifactory_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.artifactory_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.artifactory_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.artifactory_liveness_probe_failure_threshold

  depends_on = [module.config_server]
}

# Wait for Phase 3 completion
resource "time_sleep" "phase_3_complete" {
  depends_on = [module.config_server, module.artifactory]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 4: Core MOSIP Services
# ============================================================================

module "keymanager" {
  source = "../modules/keymanager"
  count  = var.enable_keymanager ? 1 : 0

  kubeconfig_path = var.kubeconfig_path
  enable_istio = var.enable_istio
  chart_version = var.keymanager_chart_version
  keygen_chart_version = var.keymanager_keygen_chart_version
  spring_config_name_env = var.keymanager_spring_config_name_env
  softhsm_cm = var.keymanager_softhsm_cm
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.keymanager_startup_probe_enabled
  startup_probe_timeout_seconds        = var.keymanager_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.keymanager_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.keymanager_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.keymanager_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.keymanager_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.keymanager_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.keymanager_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.keymanager_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.keymanager_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.keymanager_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.keymanager_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.keymanager_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.keymanager_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.keymanager_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_3_complete]
}

module "websub" {
  source = "../modules/websub"
  count  = var.websub_enabled ? 1 : 0

  helm_chart_version = var.websub_helm_chart_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.websub_startup_probe_enabled
  startup_probe_timeout_seconds        = var.websub_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.websub_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.websub_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.websub_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.websub_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.websub_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.websub_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.websub_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.websub_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.websub_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.websub_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.websub_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.websub_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.websub_liveness_probe_failure_threshold

  depends_on = [module.keymanager]
}

module "mock_smtp" {
  count  = var.mock_smtp_enabled ? 1 : 0
  source = "../modules/mock-smtp"

  mock_smtp_host    = var.mock_smtp_host
  helm_version = var.mock_smtp_helm_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.mock_smtp_startup_probe_enabled
  startup_probe_timeout_seconds        = var.mock_smtp_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.mock_smtp_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.mock_smtp_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.mock_smtp_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.mock_smtp_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.mock_smtp_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.mock_smtp_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.mock_smtp_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.mock_smtp_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.mock_smtp_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.mock_smtp_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.mock_smtp_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.mock_smtp_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.mock_smtp_liveness_probe_failure_threshold

  depends_on = [module.keymanager]
}

# Wait for Phase 4 completion
resource "time_sleep" "phase_4_complete" {
  depends_on = [module.keymanager, module.websub, module.mock_smtp]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 5: Kernel and Masterdata
# ============================================================================

module "kernel" {
  count  = var.kernel_enabled ? 1 : 0
  source = "../modules/kernel"

  namespace                   = var.kernel_namespace
  helm_chart_version         = var.kernel_helm_chart_version
  enable_insecure            = var.kernel_enable_insecure
  helm_timeout_seconds       = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.kernel_startup_probe_enabled
  startup_probe_timeout_seconds        = var.kernel_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.kernel_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.kernel_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.kernel_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.kernel_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.kernel_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.kernel_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.kernel_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.kernel_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.kernel_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.kernel_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.kernel_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.kernel_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.kernel_liveness_probe_failure_threshold

  # IDGenerator-specific Probe Configuration
  idgenerator_startup_probe_enabled                = var.kernel_idgenerator_startup_probe_enabled
  idgenerator_startup_probe_timeout_seconds        = var.kernel_idgenerator_startup_probe_timeout_seconds
  idgenerator_startup_probe_initial_delay_seconds   = var.kernel_idgenerator_startup_probe_initial_delay_seconds
  idgenerator_startup_probe_period_seconds         = var.kernel_idgenerator_startup_probe_period_seconds
  idgenerator_startup_probe_failure_threshold      = var.kernel_idgenerator_startup_probe_failure_threshold
  idgenerator_readiness_probe_enabled                = var.kernel_idgenerator_readiness_probe_enabled
  idgenerator_readiness_probe_timeout_seconds        = var.kernel_idgenerator_readiness_probe_timeout_seconds
  idgenerator_readiness_probe_initial_delay_seconds   = var.kernel_idgenerator_readiness_probe_initial_delay_seconds
  idgenerator_readiness_probe_period_seconds          = var.kernel_idgenerator_readiness_probe_period_seconds
  idgenerator_readiness_probe_failure_threshold      = var.kernel_idgenerator_readiness_probe_failure_threshold
  idgenerator_liveness_probe_enabled                = var.kernel_idgenerator_liveness_probe_enabled
  idgenerator_liveness_probe_timeout_seconds        = var.kernel_idgenerator_liveness_probe_timeout_seconds
  idgenerator_liveness_probe_initial_delay_seconds    = var.kernel_idgenerator_liveness_probe_initial_delay_seconds
  idgenerator_liveness_probe_period_seconds         = var.kernel_idgenerator_liveness_probe_period_seconds
  idgenerator_liveness_probe_failure_threshold       = var.kernel_idgenerator_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_4_complete]
}

module "masterdata_loader" {
  source = "../modules/masterdata-loader"
  count  = var.masterdata_loader_enabled ? 1 : 0

  helm_chart_version      = var.masterdata_loader_helm_chart_version
  mosip_data_github_branch = var.masterdata_loader_mosip_data_github_branch
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.masterdata_loader_startup_probe_enabled
  startup_probe_timeout_seconds        = var.masterdata_loader_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.masterdata_loader_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.masterdata_loader_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.masterdata_loader_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.masterdata_loader_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.masterdata_loader_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.masterdata_loader_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.masterdata_loader_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.masterdata_loader_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.masterdata_loader_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.masterdata_loader_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.masterdata_loader_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.masterdata_loader_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.masterdata_loader_liveness_probe_failure_threshold

  depends_on = [module.kernel]
}

# Wait for Phase 5 completion
resource "time_sleep" "phase_5_complete" {
  depends_on = [module.kernel, module.masterdata_loader]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 6: Registration Services
# ============================================================================

module "biosdk" {
  source = "../modules/biosdk"
  count  = var.biosdk_enabled ? 1 : 0

  namespace                   = var.biosdk_namespace
  helm_chart_version         = var.biosdk_helm_chart_version
  istio_injection_label      = "enabled"
  helm_timeout_seconds       = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.biosdk_startup_probe_enabled
  startup_probe_timeout_seconds        = var.biosdk_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.biosdk_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.biosdk_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.biosdk_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.biosdk_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.biosdk_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.biosdk_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.biosdk_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.biosdk_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.biosdk_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.biosdk_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.biosdk_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.biosdk_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.biosdk_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_5_complete]
}

module "packetmanager" {
  source = "../modules/packetmanager"
  count  = var.packetmanager_enabled ? 1 : 0

  namespace                   = var.packetmanager_namespace
  helm_chart_version         = var.packetmanager_helm_chart_version
  istio_injection_label      = "enabled"
  helm_timeout_seconds       = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.packetmanager_startup_probe_enabled
  startup_probe_timeout_seconds        = var.packetmanager_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.packetmanager_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.packetmanager_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.packetmanager_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.packetmanager_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.packetmanager_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.packetmanager_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.packetmanager_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.packetmanager_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.packetmanager_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.packetmanager_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.packetmanager_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.packetmanager_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.packetmanager_liveness_probe_failure_threshold

  depends_on = [module.biosdk]
}

module "datashare" {
  source = "../modules/datashare"
  count  = var.datashare_enabled ? 1 : 0

  namespace                   = var.datashare_namespace
  helm_chart_version         = var.datashare_helm_chart_version
  istio_injection_label      = "enabled"
  helm_timeout_seconds       = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.datashare_startup_probe_enabled
  startup_probe_timeout_seconds        = var.datashare_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.datashare_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.datashare_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.datashare_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.datashare_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.datashare_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.datashare_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.datashare_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.datashare_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.datashare_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.datashare_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.datashare_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.datashare_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.datashare_liveness_probe_failure_threshold

  depends_on = [module.packetmanager]
}

module "prereg" {
  source = "../modules/prereg"
  count  = var.prereg_enabled ? 1 : 0

  namespace           = var.prereg_namespace
  helm_chart_version  = var.prereg_chart_version
  prereg_gateway_chart_version = var.prereg_gateway_chart_version
  prereg_booking_chart_version = var.prereg_booking_chart_version
  prereg_ui_chart_version      = var.prereg_ui_chart_version
  istio_injection_label = var.prereg_istio_injection_label
  helm_timeout_seconds = var.global_helm_timeout_seconds
  rate_limit_max_tokens = var.prereg_rate_limit_max_tokens
  rate_limit_tokens_per_fill = var.prereg_rate_limit_tokens_per_fill
  rate_limit_fill_interval = var.prereg_rate_limit_fill_interval

  # Startup Probe Configuration
  startup_probe_enabled                = var.prereg_startup_probe_enabled
  startup_probe_timeout_seconds        = var.prereg_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.prereg_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.prereg_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.prereg_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.prereg_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.prereg_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.prereg_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.prereg_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.prereg_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.prereg_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.prereg_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.prereg_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.prereg_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.prereg_liveness_probe_failure_threshold

  depends_on = [module.datashare]
}

# Wait for Phase 6 completion
resource "time_sleep" "phase_6_complete" {
  depends_on = [module.biosdk, module.packetmanager, module.datashare, module.prereg]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 7: Identity Services
# ============================================================================

module "idrepo" {
  source = "../modules/idrepo"
  count  = var.idrepo_enabled ? 1 : 0

  namespace                   = var.idrepo_namespace
  helm_chart_version         = var.idrepo_helm_chart_version
  istio_injection_label      = var.idrepo_istio_injection_label
  helm_timeout_seconds       = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.idrepo_startup_probe_enabled
  startup_probe_timeout_seconds        = var.idrepo_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.idrepo_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.idrepo_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.idrepo_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.idrepo_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.idrepo_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.idrepo_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.idrepo_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.idrepo_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.idrepo_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.idrepo_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.idrepo_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.idrepo_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.idrepo_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_6_complete]
}

module "pms" {
  source = "../modules/pms"
  count  = var.pms_enabled ? 1 : 0

  namespace                   = var.pms_namespace
  helm_chart_version         = var.pms_helm_chart_version
  pmp_ui_chart_version       = var.pmp_ui_chart_version
  pmp_revamp_ui_enabled      = var.pmp_revamp_ui_enabled
  pmp_revamp_ui_chart_version = var.pmp_revamp_ui_chart_version
  istio_injection_label      = var.pms_istio_injection_label
  helm_timeout_seconds       = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.pms_startup_probe_enabled
  startup_probe_timeout_seconds        = var.pms_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.pms_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.pms_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.pms_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.pms_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.pms_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.pms_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.pms_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.pms_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.pms_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.pms_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.pms_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.pms_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.pms_liveness_probe_failure_threshold

  depends_on = [module.idrepo]
}

module "mock_abis" {
  source = "../modules/mock-abis"
  count  = var.mock_abis_enabled || var.mock_mv_enabled ? 1 : 0

  namespace                    = var.mock_abis_namespace
  enable_mock_abis            = var.mock_abis_enabled
  enable_mock_mv              = var.mock_mv_enabled
  mock_abis_helm_chart_version = var.mock_abis_helm_chart_version
  mock_mv_helm_chart_version   = var.mock_mv_helm_chart_version
  istio_injection_label       = var.mock_abis_istio_injection_label
  helm_timeout_seconds        = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.mock_abis_startup_probe_enabled
  startup_probe_timeout_seconds        = var.mock_abis_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.mock_abis_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.mock_abis_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.mock_abis_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.mock_abis_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.mock_abis_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.mock_abis_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.mock_abis_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.mock_abis_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.mock_abis_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.mock_abis_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.mock_abis_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.mock_abis_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.mock_abis_liveness_probe_failure_threshold

  depends_on = [module.pms]
}

# Wait for Phase 7 completion
resource "time_sleep" "phase_7_complete" {
  depends_on = [module.idrepo, module.pms, module.mock_abis]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 8: Processing Services
# ============================================================================

module "regproc" {
  source = "../modules/regproc"
  count  = var.regproc_enabled ? 1 : 0

  namespace         = var.regproc_namespace
  helm_chart_version = var.regproc_helm_chart_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.regproc_startup_probe_enabled
  startup_probe_timeout_seconds        = var.regproc_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.regproc_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.regproc_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.regproc_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.regproc_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.regproc_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.regproc_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.regproc_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.regproc_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.regproc_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.regproc_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.regproc_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.regproc_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.regproc_liveness_probe_failure_threshold

  # Regproc Group2-specific Probe Configuration
  regproc_group2_startup_probe_enabled                = var.regproc_group2_startup_probe_enabled
  regproc_group2_startup_probe_timeout_seconds        = var.regproc_group2_startup_probe_timeout_seconds
  regproc_group2_startup_probe_initial_delay_seconds   = var.regproc_group2_startup_probe_initial_delay_seconds
  regproc_group2_startup_probe_period_seconds         = var.regproc_group2_startup_probe_period_seconds
  regproc_group2_startup_probe_failure_threshold      = var.regproc_group2_startup_probe_failure_threshold
  regproc_group2_readiness_probe_enabled                = var.regproc_group2_readiness_probe_enabled
  regproc_group2_readiness_probe_timeout_seconds        = var.regproc_group2_readiness_probe_timeout_seconds
  regproc_group2_readiness_probe_initial_delay_seconds   = var.regproc_group2_readiness_probe_initial_delay_seconds
  regproc_group2_readiness_probe_period_seconds          = var.regproc_group2_readiness_probe_period_seconds
  regproc_group2_readiness_probe_failure_threshold      = var.regproc_group2_readiness_probe_failure_threshold
  regproc_group2_liveness_probe_enabled                = var.regproc_group2_liveness_probe_enabled
  regproc_group2_liveness_probe_timeout_seconds        = var.regproc_group2_liveness_probe_timeout_seconds
  regproc_group2_liveness_probe_initial_delay_seconds    = var.regproc_group2_liveness_probe_initial_delay_seconds
  regproc_group2_liveness_probe_period_seconds         = var.regproc_group2_liveness_probe_period_seconds
  regproc_group2_liveness_probe_failure_threshold       = var.regproc_group2_liveness_probe_failure_threshold

  # Regproc Notifier-specific Probe Configuration
  regproc_notifier_startup_probe_enabled                = var.regproc_notifier_startup_probe_enabled
  regproc_notifier_startup_probe_timeout_seconds        = var.regproc_notifier_startup_probe_timeout_seconds
  regproc_notifier_startup_probe_initial_delay_seconds   = var.regproc_notifier_startup_probe_initial_delay_seconds
  regproc_notifier_startup_probe_period_seconds         = var.regproc_notifier_startup_probe_period_seconds
  regproc_notifier_startup_probe_failure_threshold      = var.regproc_notifier_startup_probe_failure_threshold
  regproc_notifier_readiness_probe_enabled                = var.regproc_notifier_readiness_probe_enabled
  regproc_notifier_readiness_probe_timeout_seconds        = var.regproc_notifier_readiness_probe_timeout_seconds
  regproc_notifier_readiness_probe_initial_delay_seconds   = var.regproc_notifier_readiness_probe_initial_delay_seconds
  regproc_notifier_readiness_probe_period_seconds          = var.regproc_notifier_readiness_probe_period_seconds
  regproc_notifier_readiness_probe_failure_threshold      = var.regproc_notifier_readiness_probe_failure_threshold
  regproc_notifier_liveness_probe_enabled                = var.regproc_notifier_liveness_probe_enabled
  regproc_notifier_liveness_probe_timeout_seconds        = var.regproc_notifier_liveness_probe_timeout_seconds
  regproc_notifier_liveness_probe_initial_delay_seconds    = var.regproc_notifier_liveness_probe_initial_delay_seconds
  regproc_notifier_liveness_probe_period_seconds         = var.regproc_notifier_liveness_probe_period_seconds
  regproc_notifier_liveness_probe_failure_threshold       = var.regproc_notifier_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_7_complete]
}

module "admin" {
  source = "../modules/admin"
  count  = var.admin_enabled ? 1 : 0

  namespace         = var.admin_namespace
  helm_chart_version = var.admin_helm_chart_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.admin_startup_probe_enabled
  startup_probe_timeout_seconds        = var.admin_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.admin_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.admin_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.admin_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.admin_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.admin_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.admin_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.admin_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.admin_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.admin_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.admin_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.admin_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.admin_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.admin_liveness_probe_failure_threshold

  # Admin-Service-specific Probe Configuration
  admin_service_startup_probe_enabled                = var.admin_service_startup_probe_enabled
  admin_service_startup_probe_timeout_seconds        = var.admin_service_startup_probe_timeout_seconds
  admin_service_startup_probe_initial_delay_seconds   = var.admin_service_startup_probe_initial_delay_seconds
  admin_service_startup_probe_period_seconds         = var.admin_service_startup_probe_period_seconds
  admin_service_startup_probe_failure_threshold      = var.admin_service_startup_probe_failure_threshold
  admin_service_readiness_probe_enabled                = var.admin_service_readiness_probe_enabled
  admin_service_readiness_probe_timeout_seconds        = var.admin_service_readiness_probe_timeout_seconds
  admin_service_readiness_probe_initial_delay_seconds   = var.admin_service_readiness_probe_initial_delay_seconds
  admin_service_readiness_probe_period_seconds          = var.admin_service_readiness_probe_period_seconds
  admin_service_readiness_probe_failure_threshold      = var.admin_service_readiness_probe_failure_threshold
  admin_service_liveness_probe_enabled                = var.admin_service_liveness_probe_enabled
  admin_service_liveness_probe_timeout_seconds        = var.admin_service_liveness_probe_timeout_seconds
  admin_service_liveness_probe_initial_delay_seconds    = var.admin_service_liveness_probe_initial_delay_seconds
  admin_service_liveness_probe_period_seconds         = var.admin_service_liveness_probe_period_seconds
  admin_service_liveness_probe_failure_threshold       = var.admin_service_liveness_probe_failure_threshold

  depends_on = [module.regproc]
}

# Wait for Phase 8 completion
resource "time_sleep" "phase_8_complete" {
  depends_on = [module.regproc, module.admin]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 9: Authentication and Printing
# ============================================================================

module "ida" {
  source = "../modules/ida"
  count  = var.ida_enabled ? 1 : 0

  namespace         = var.ida_namespace
  helm_chart_version = var.ida_helm_chart_version
  enable_insecure   = var.ida_enable_insecure
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.ida_startup_probe_enabled
  startup_probe_timeout_seconds        = var.ida_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.ida_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.ida_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.ida_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.ida_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.ida_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.ida_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.ida_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.ida_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.ida_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.ida_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.ida_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.ida_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.ida_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_8_complete]
}

module "print" {
  source = "../modules/print"
  count  = var.print_enabled ? 1 : 0

  namespace         = var.print_namespace
  helm_chart_version = var.print_helm_chart_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.print_startup_probe_enabled
  startup_probe_timeout_seconds        = var.print_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.print_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.print_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.print_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.print_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.print_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.print_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.print_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.print_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.print_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.print_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.print_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.print_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.print_liveness_probe_failure_threshold

  depends_on = [module.ida]
}

# Wait for Phase 9 completion
resource "time_sleep" "phase_9_complete" {
  depends_on = [module.ida, module.print]
  create_duration = var.module_wait_seconds > 0 ? "${var.module_wait_seconds}s" : "0s"
}

# ============================================================================
# PHASE 10: Resident and Client Services
# ============================================================================

module "resident" {
  source = "../modules/resident"
  count  = var.resident_enabled ? 1 : 0

  namespace          = var.resident_namespace
  helm_chart_version = var.resident_helm_chart_version
  ui_chart_version   = var.resident_ui_chart_version
  enable_insecure    = var.resident_enable_insecure
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.resident_startup_probe_enabled
  startup_probe_timeout_seconds        = var.resident_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.resident_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.resident_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.resident_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.resident_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.resident_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.resident_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.resident_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.resident_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.resident_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.resident_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.resident_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.resident_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.resident_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_9_complete]
}

module "partner_onboarder" {
  source = "../modules/partner-onboarder"
  count  = var.partner_onboarder_enabled ? 1 : 0

  namespace         = var.partner_onboarder_namespace
  helm_chart_version = var.partner_onboarder_helm_chart_version
  s3_bucket_name    = var.partner_onboarder_s3_bucket_name
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.partner_onboarder_startup_probe_enabled
  startup_probe_timeout_seconds        = var.partner_onboarder_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.partner_onboarder_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.partner_onboarder_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.partner_onboarder_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.partner_onboarder_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.partner_onboarder_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.partner_onboarder_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.partner_onboarder_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.partner_onboarder_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.partner_onboarder_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.partner_onboarder_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.partner_onboarder_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.partner_onboarder_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.partner_onboarder_liveness_probe_failure_threshold

  depends_on = [module.resident]
}

module "regclient" {
  source = "../modules/regclient"
  count  = var.regclient_enabled ? 1 : 0

  namespace          = var.regclient_namespace
  helm_chart_version = var.regclient_helm_chart_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  # Startup Probe Configuration
  startup_probe_enabled                = var.regclient_startup_probe_enabled
  startup_probe_timeout_seconds        = var.regclient_startup_probe_timeout_seconds
  startup_probe_initial_delay_seconds   = var.regclient_startup_probe_initial_delay_seconds
  startup_probe_period_seconds         = var.regclient_startup_probe_period_seconds
  startup_probe_failure_threshold      = var.regclient_startup_probe_failure_threshold

  # Readiness Probe Configuration
  readiness_probe_enabled                = var.regclient_readiness_probe_enabled
  readiness_probe_timeout_seconds        = var.regclient_readiness_probe_timeout_seconds
  readiness_probe_initial_delay_seconds   = var.regclient_readiness_probe_initial_delay_seconds
  readiness_probe_period_seconds          = var.regclient_readiness_probe_period_seconds
  readiness_probe_failure_threshold      = var.regclient_readiness_probe_failure_threshold

  # Liveness Probe Configuration
  liveness_probe_enabled                = var.regclient_liveness_probe_enabled
  liveness_probe_timeout_seconds        = var.regclient_liveness_probe_timeout_seconds
  liveness_probe_initial_delay_seconds    = var.regclient_liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds         = var.regclient_liveness_probe_period_seconds
  liveness_probe_failure_threshold       = var.regclient_liveness_probe_failure_threshold

  depends_on = [time_sleep.phase_9_complete]
}

module "mosip_file_server" {
  source = "../modules/mosip-file-server"
  count  = var.mosip_file_server_enabled ? 1 : 0

  namespace           = var.mosip_file_server_namespace
  helm_chart_version  = var.mosip_file_server_helm_chart_version
  helm_timeout_seconds = var.global_helm_timeout_seconds

  depends_on = [time_sleep.phase_9_complete]
}
