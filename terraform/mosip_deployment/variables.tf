variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig file"
}

variable "installation_name" {
  type        = string
  description = "Name of the MOSIP installation"
}

variable "installation_domain" {
  type        = string
  description = "Domain name for the MOSIP installation"
}

variable "mosip_version" {
  type        = string
  description = "MOSIP version to deploy"
}

variable "is_glowroot_env" {
  type        = string
  description = "Whether to enable Glowroot for Java profiling"
  default     = "absent"
}

# Longhorn Variables
variable "longhorn_enable" {
  type        = bool
  description = "Whether to enable Longhorn deployment"
  default     = true
}

variable "longhorn_namespace" {
  description = "Namespace to deploy Longhorn"
  type        = string
  default     = "longhorn-system"
}

variable "longhorn_version" {
  description = "Version of Longhorn to deploy"
  type        = string
}

variable "longhorn_replica_count" {
  description = "Number of replicas for Longhorn volumes"
  type        = number
  default     = 1
}

variable "longhorn_guaranteed_engine_cpu" {
  description = "Guaranteed CPU for engine manager"
  type        = string
  default     = "5"
}

variable "longhorn_guaranteed_replica_cpu" {
  description = "Guaranteed CPU for replica manager"
  type        = string
  default     = "5"
}

variable "longhorn_storage_minimal_available_percentage" {
  description = "Minimal available percentage for storage"
  type        = string
  default     = "25"
}

variable "longhorn_storage_over_provisioning_percentage" {
  description = "Storage over-provisioning percentage"
  type        = string
  default     = "200"
}

variable "longhorn_storage_reserved_percentage" {
  description = "Reserved storage percentage"
  type        = string
  default     = "25"
}

variable "longhorn_auto_salvage" {
  description = "Enable auto salvage"
  type        = string
  default     = "true"
}

variable "longhorn_auto_delete_pod_when_volume_detached_unexpectedly" {
  description = "Auto delete pod when volume detached"
  type        = string
  default     = "true"
}

variable "longhorn_disable_scheduling_on_cordoned_node" {
  description = "Disable scheduling on cordoned nodes"
  type        = string
  default     = "true"
}

variable "longhorn_replica_zone_soft_anti_affinity" {
  description = "Enable replica zone soft anti-affinity"
  type        = string
  default     = "true"
}

variable "longhorn_storage_class_name" {
  description = "Name of the storage class"
  type        = string
  default     = "longhorn"
}

# Ingress Nginx Variables
variable "ingress_nginx_namespace" {
  type        = string
  description = "Namespace for ingress-nginx"
  default     = "ingress-nginx"
}

variable "ingress_nginx_version" {
  type        = string
  description = "Version of ingress-nginx Helm chart"
  default     = "4.0.18"
}

variable "ingress_nginx_values" {
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
  description = "Values for ingress-nginx Helm chart"
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

# Istio Variables
variable "enable_istio" {
  type        = bool
  description = "Whether to enable Istio deployment"
  default     = true
}

variable "istio_version" {
  type        = string
  description = "Version of Istio to install"
  default     = "1.15.0"
}

variable "istio_namespace" {
  type        = string
  description = "Namespace for Istio components"
  default     = "istio-system"
}

variable "proxy_protocol_enabled" {
  type        = bool
  description = "Whether to enable proxy protocol for Istio gateways"
  default     = false
}

# httpbin variables
variable "httpbin_enable" {
  description = "Enable httpbin deployment"
  type        = bool
  default     = false
}

variable "httpbin_namespace" {
  description = "Namespace for httpbin deployment"
  type        = string
  default     = "httpbin"
}

# Postgres variables
variable "postgres_enable" {
  description = "Whether to enable Postgres deployment"
  type        = bool
  default     = true
}

variable "postgres_version" {
  description = "Version of the Postgres Helm chart"
  type        = string
  default     = "12.11.1"
}

variable "postgres_namespace" {
  description = "Namespace for Postgres deployment"
  type        = string
  default     = "postgres"
}

variable "postgres_init_version" {
  description = "Version of the Postgres Init Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "bitnami_image_repository" {
  description = "Docker image repository prefix for Bitnami charts (e.g., 'bitnami', 'bitnamilegacy', or 'mosipid')"
  type        = string
  default     = "mosipid"
}

# IAM variables
variable "iam_enable" {
  description = "Enable IAM (Keycloak) deployment"
  type        = bool
  default     = true
}

variable "iam_version" {
  description = "Version of the Keycloak Helm chart"
  type        = string
  default     = "7.1.18"  # Matching shell script version
}

variable "iam_init_version" {
  description = "Version of the Keycloak init Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "iam_namespace" {
  description = "Namespace for IAM deployment"
  type        = string
  default     = "keycloak"
}

variable "iam_admin_password" {
  description = "Initial admin password for Keycloak"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "iam_image_repository" {
  description = "Keycloak image repository"
  type        = string
  default     = "mosipid/mosip-artemis-keycloak"
}

variable "iam_image_tag" {
  description = "Keycloak image tag"
  type        = string
  default     = "1.2.0.1"
}

variable "iam_image_pull_policy" {
  description = "Image pull policy for Keycloak"
  type        = string
  default     = "Always"
}

# Add new SMTP configuration variables
variable "iam_smtp_host" {
  description = "SMTP host for Keycloak email configuration"
  type        = string
}

variable "iam_smtp_port" {
  description = "SMTP port for Keycloak email configuration"
  type        = string
}

variable "iam_smtp_from" {
  description = "From email address for Keycloak emails"
  type        = string
}

variable "iam_smtp_starttls" {
  description = "Enable STARTTLS for SMTP"
  type        = bool
  default     = false
}

variable "iam_smtp_auth" {
  description = "Enable SMTP authentication"
  type        = bool
  default     = true
}

variable "iam_smtp_ssl" {
  description = "Enable SSL for SMTP"
  type        = bool
  default     = true
}

variable "iam_smtp_username" {
  description = "SMTP username if auth enabled"
  type        = string
  default     = ""
}

variable "iam_smtp_password" {
  description = "SMTP password if auth enabled"
  type        = string
  default     = ""
  sensitive   = true
}

# SoftHSM variables
variable "enable_softhsm" {
  description = "Whether to enable SoftHSM deployment for cryptographic key storage"
  type        = bool
  default     = true
}

variable "softhsm_chart_version" {
  description = "Version of the SoftHSM Helm chart to deploy (must match MOSIP version compatibility)"
  type        = string
  default     = "12.0.1"
}

variable "softhsm_namespace" {
  description = "Namespace for SoftHSM deployment"
  type        = string
  default     = "softhsm"
}

variable "enable_minio" {
  description = "Flag to enable/disable MinIO deployment"
  type        = bool
  default     = true
}

variable "minio_chart_version" {
  description = "Version of the MinIO Helm chart"
  type        = string
  default     = "10.1.6"
}

variable "minio_namespace" {
  description = "Namespace for MinIO deployment"
  type        = string
  default     = "minio"
}

# S3 Credentials Configuration
variable "create_s3_namespace" {
  description = "Flag to create S3 namespace and credentials"
  type        = bool
  default     = false
}

variable "use_existing_minio" {
  description = "Use credentials from existing MinIO installation"
  type        = bool
  default     = true
}

variable "s3_user_key" {
  description = "S3 user key (only used if use_existing_minio is false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_user_secret" {
  description = "S3 user secret (only used if use_existing_minio is false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_region" {
  description = "S3 region (only used if use_existing_minio is false)"
  type        = string
  default     = ""
}

variable "s3_pretext_value" {
  description = "S3 pretext value for object store configuration"
  type        = string
  default     = ""
}

variable "enable_activemq" {
  description = "Whether to enable ActiveMQ deployment"
  type        = bool
  default     = true
}

# Kafka Configuration
variable "enable_kafka" {
  description = "Flag to enable/disable Kafka deployment"
  type        = bool
  default     = true
}

variable "kafka_replica_count" {
  description = "Number of Kafka replicas"
  type        = number
  default     = 5
}

variable "kafka_storage_size" {
  description = "Storage size for Kafka PVC"
  type        = string
  default     = "8Gi"
}

variable "kafka_zookeeper_storage_size" {
  description = "Storage size for Zookeeper PVC"
  type        = string
  default     = "2Gi"
}

variable "kafka_zookeeper_replica_count" {
  description = "Number of Zookeeper replicas"
  type        = number
  default     = 5
}

# ClamAV Configuration
variable "enable_clamav" {
  type        = bool
  description = "Feature flag for ClamAV deployment"
  default     = true
}

variable "clamav_helm_chart_version" {
  type        = string
  description = "ClamAV Helm chart version"
  default     = "2.4.1"
}

variable "clamav_replica_count" {
  type        = number
  description = "Number of ClamAV replicas"
  default     = 1
}

variable "clamav_image_repository" {
  type        = string
  description = "ClamAV image repository"
  default     = "clamav/clamav"
}

variable "clamav_image_tag" {
  type        = string
  description = "ClamAV image tag"
  default     = "latest"
}

variable "clamav_image_pull_policy" {
  type        = string
  description = "Image pull policy for ClamAV"
  default     = "Always"
}

# MSG Gateway Configuration
variable "msg_gateway_enabled" {
  type        = bool
  description = "Enable or disable msg-gateway module"
  default     = true
}

variable "smtp_host" {
  type        = string
  description = "SMTP host address"
  default     = "mock-smtp.mock-smtp"
}

variable "sms_host" {
  type        = string
  description = "SMS host address"
  default     = "mock-smtp.mock-smtp"
}

variable "smtp_port" {
  type        = string
  description = "SMTP port"
  default     = "8025"
}

variable "sms_port" {
  type        = string
  description = "SMS port"
  default     = "8080"
}

variable "smtp_username" {
  type        = string
  description = "SMTP username"
  default     = ""
}

variable "sms_username" {
  type        = string
  description = "SMS username"
  default     = ""
}

variable "smtp_secret" {
  type        = string
  description = "SMTP secret"
  default     = "''"
}

variable "sms_secret" {
  type        = string
  description = "SMS secret"
  default     = "''"
}

variable "sms_authkey" {
  type        = string
  description = "SMS auth key"
  default     = "authkey"
}

# Docker Secrets Configuration
variable "docker_secrets_enabled" {
  description = "Enable or disable docker secrets"
  type        = bool
  default     = false
}

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
  sensitive   = true
}

variable "docker_email" {
  description = "Docker registry email"
  type        = string
  default     = ""
}

# Conf Secrets variables
variable "conf_secrets_enabled" {
  description = "Enable or disable conf secrets"
  type        = bool
  default     = true
}

variable "conf_secrets_namespace" {
  description = "Namespace for conf secrets"
  type        = string
  default     = "conf-secrets"
}

variable "conf_secrets_chart_version" {
  description = "Version of the conf-secrets Helm chart"
  type        = string
  default     = "12.0.1"
}

# Config Server Variables
variable "config_server_enabled" {
  description = "Flag to enable/disable config-server deployment"
  type        = bool
  default     = true
}

variable "config_server_namespace" {
  description = "Namespace for config-server deployment"
  type        = string
  default     = "config-server"
}

variable "config_server_chart_version" {
  description = "Version of the config-server Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "config_server_git_repo_uri" {
  description = "Git repository URI for config server"
  type        = string
  default     = "https://github.com/mosip/mosip-config"
}

variable "config_server_git_repo_version" {
  description = "Git repository version/branch/tag for config server"
  type        = string
  default     = "v1.2.0.1"
}

variable "config_server_git_search_folders" {
  description = "Folders within the base repo where properties may be found"
  type        = string
  default     = ""
}

variable "config_server_git_private" {
  description = "Whether the Git repository is private"
  type        = bool
  default     = false
}

variable "config_server_git_username" {
  description = "Username for private Git repository access"
  type        = string
  default     = ""
}

variable "config_server_git_token" {
  description = "Token for private Git repository access"
  type        = string
  default     = ""
  sensitive   = true
}

# Landing Page variables
variable "enable_landing_page" {
  description = "Flag to enable/disable Landing Page deployment"
  type        = bool
  default     = true
}

variable "landing_page_chart_version" {
  description = "Version of Landing Page Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "landing_version" {
  description = "Version of Landing Page"
  type        = string
  default     = "1.2.0.2"
}

variable "healthservices_host" {
  description = "Health Services host URL"
  type        = string
  default     = "healthservices.mosip.net"
}

# Captcha Configuration
variable "enable_captcha" {
  description = "Whether to enable Captcha deployment"
  type        = bool
  default     = true
}

variable "captcha_namespace" {
  description = "Namespace for Captcha deployment"
  type        = string
  default     = "captcha"
}

variable "prereg_captcha_site_key" {
  description = "Recaptcha admin site key for PreReg domain"
  type        = string
  default     = ""
}

variable "prereg_captcha_secret_key" {
  description = "Recaptcha admin secret key for PreReg domain"
  type        = string
  default     = ""
}

variable "resident_captcha_site_key" {
  description = "Recaptcha admin site key for Resident domain"
  type        = string
  default     = ""
}

variable "resident_captcha_secret_key" {
  description = "Recaptcha admin secret key for Resident domain"
  type        = string
  default     = ""
}

# Artifactory Variables
variable "artifactory_enable" {
  description = "Flag to enable/disable artifactory deployment"
  type        = bool
  default     = true
}

variable "artifactory_namespace" {
  description = "Namespace for artifactory deployment"
  type        = string
  default     = "artifactory"
}

variable "artifactory_chart_version" {
  description = "Version of the artifactory Helm chart"
  type        = string
  default     = "12.0.2"
}

variable "artifactory_startup_probe_timeout" {
  description = "Timeout seconds for startup probe"
  type        = number
  default     = 90
}

variable "artifactory_startup_probe_initial_delay" {
  description = "Initial delay seconds for startup probe"
  type        = number
  default     = 90
}

# Keymanager variables
variable "enable_keymanager" {
  description = "Flag to enable/disable keymanager deployment"
  type        = bool
  default     = true
}

variable "keymanager_chart_version" {
  description = "Version of the keymanager Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "keymanager_keygen_chart_version" {
  description = "Version of the keygen Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "keymanager_spring_config_name_env" {
  description = "Spring config name environment for keymanager"
  type        = string
  default     = "kernel"
}

variable "keymanager_softhsm_cm" {
  description = "SoftHSM ConfigMap name for keymanager"
  type        = string
  default     = "softhsm-kernel-share"
}

variable "keymanager_startup_probe_timeout" {
  description = "Timeout seconds for startup probe in keymanager"
  type        = number
  default     = 90
}

variable "keymanager_startup_probe_initial_delay" {
  description = "Initial delay seconds for startup probe in keymanager"
  type        = number
  default     = 90
}

variable "websub_enabled" {
  description = "Enable or disable websub deployment"
  type        = bool
  default     = true
}

variable "websub_helm_chart_version" {
  description = "Websub helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "websub_startup_probe_timeout" {
  description = "Timeout seconds for startup probe in websub"
  type        = number
  default     = 120
}

variable "websub_startup_probe_initial_delay" {
  description = "Initial delay seconds for startup probe in websub"
  type        = number
  default     = 90
}

variable "mock_smtp_enabled" {
  type        = bool
  description = "Flag to enable/disable mock-smtp module"
  default     = true
}

variable "mock_smtp_helm_version" {
  type        = string
  description = "Helm chart version for mock-smtp"
  default     = "1.0.0"
}

variable "mock_smtp_host" {
  type        = string
  description = "SMTP host value"
}

variable "kernel_enabled" {
  description = "Enable kernel module"
  type        = bool
  default     = true
}

variable "kernel_namespace" {
  description = "Namespace for kernel deployment"
  type        = string
  default     = "kernel"
}

variable "kernel_helm_chart_version" {
  description = "Helm chart version for kernel components"
  type        = string
  default     = "12.0.1"
}

variable "kernel_enable_insecure" {
  description = "Enable insecure mode for kernel components that support it"
  type        = bool
  default     = false
}

variable "kernel_startup_probe_timeout" {
  description = "Timeout for kernel startup probe"
  type        = number
  default     = 180
}

variable "kernel_startup_probe_initial_delay" {
  description = "Initial delay for kernel startup probe"
  type        = number
  default     = 90
}

variable "kernel_helm_timeout_seconds" {
  description = "Timeout for kernel helm operations"
  type        = number
  default     = 1200  # 20 minutes
}

# Monitoring Variables
variable "monitoring_namespace" {
  description = "Namespace for Rancher monitoring"
  type        = string
  default     = "cattle-monitoring-system"
}

variable "monitoring_crd_version" {
  description = "Version of Rancher monitoring CRD chart"
  type        = string
  default     = ""
}

variable "monitoring_version" {
  description = "Version of Rancher monitoring chart"
  type        = string
  default     = ""
}

variable "masterdata_loader_enabled" {
  description = "Enable or disable masterdata-loader deployment"
  type        = bool
  default     = true
}

variable "masterdata_loader_helm_chart_version" {
  description = "Masterdata loader helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "masterdata_loader_mosip_data_github_branch" {
  description = "MOSIP data Github branch for masterdata loader"
  type        = string
  default     = "v1.2.0.1"
}

variable "masterdata_loader_startup_probe_timeout" {
  description = "Timeout seconds for masterdata loader startup probe"
  type        = number
  default     = 180
}

variable "masterdata_loader_startup_probe_initial_delay" {
  description = "Initial delay seconds for masterdata loader startup probe"
  type        = number
  default     = 90
}

variable "biosdk_enabled" {
  description = "Enable biosdk module"
  type        = bool
  default     = true
}

variable "biosdk_namespace" {
  description = "Namespace for biosdk"
  type        = string
  default     = "biosdk"
}

variable "packetmanager_enabled" {
  description = "Enable packetmanager module"
  type        = bool
  default     = true
}

variable "packetmanager_namespace" {
  description = "Namespace for packetmanager"
  type        = string
  default     = "packetmanager"
}

variable "datashare_enabled" {
  description = "Enable datashare module"
  type        = bool
  default     = true
}

variable "datashare_namespace" {
  description = "Namespace for datashare"
  type        = string
  default     = "datashare"
}

# BioSDK variables
variable "biosdk_helm_chart_version" {
  description = "Version of the biosdk Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "biosdk_startup_probe_timeout" {
  description = "Timeout for biosdk startup probe"
  type        = number
  default     = 180
}

variable "biosdk_startup_probe_initial_delay" {
  description = "Initial delay for biosdk startup probe"
  type        = number
  default     = 90
}

# Packetmanager variables
variable "packetmanager_helm_chart_version" {
  description = "Version of the packetmanager Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "packetmanager_startup_probe_timeout" {
  description = "Timeout for packetmanager startup probe"
  type        = number
  default     = 180
}

variable "packetmanager_startup_probe_initial_delay" {
  description = "Initial delay for packetmanager startup probe"
  type        = number
  default     = 90
}

# Datashare variables
variable "datashare_helm_chart_version" {
  description = "Version of the datashare Helm chart"
  type        = string
  default     = "12.0.1"
}

variable "datashare_startup_probe_timeout" {
  description = "Timeout for datashare startup probe"
  type        = number
  default     = 180
}

variable "datashare_startup_probe_initial_delay" {
  description = "Initial delay for datashare startup probe"
  type        = number
  default     = 90
}

variable "datashare_chart_version" {
  description = "Datashare helm chart version"
  type        = string
  default     = "12.0.1"
}

# Prereg variables
variable "prereg_enabled" {
  description = "Flag to enable/disable prereg module"
  type        = bool
  default     = true
}

variable "prereg_namespace" {
  description = "Namespace for prereg"
  type        = string
  default     = "prereg"
}

variable "prereg_chart_version" {
  description = "Prereg helm chart version"
  type        = string
  default     = "12.0.1"
}

variable "prereg_istio_injection_label" {
  description = "Istio injection label for prereg namespace"
  type        = string
  default     = "disabled"
}

variable "prereg_startup_probe_timeout" {
  description = "Timeout for startup probe in prereg"
  type        = number
  default     = 180
}

variable "prereg_startup_probe_initial_delay" {
  description = "Initial delay for startup probe in prereg"
  type        = number
  default     = 90
}

variable "prereg_helm_timeout_seconds" {
  description = "Timeout for helm operations in prereg"
  type        = number
  default     = 1200
}

variable "prereg_rate_limit_max_tokens" {
  description = "Maximum tokens for rate limiting in prereg"
  type        = number
  default     = 100
}

variable "prereg_rate_limit_tokens_per_fill" {
  description = "Tokens per fill for rate limiting in prereg"
  type        = number
  default     = 100
}

variable "prereg_rate_limit_fill_interval" {
  description = "Fill interval for rate limiting in prereg"
  type        = string
  default     = "50ms"
}

# IDREPO Variables
variable "idrepo_enabled" {
  description = "Flag to enable/disable IDREPO module"
  type        = bool
  default     = true
}

variable "idrepo_namespace" {
  description = "Namespace for IDREPO module"
  type        = string
  default     = "idrepo"
}

variable "idrepo_helm_chart_version" {
  description = "Helm chart version for IDREPO"
  type        = string
  default     = "12.0.1"
}

variable "idrepo_istio_injection_label" {
  description = "Istio injection label for IDREPO namespace"
  type        = string
  default     = "enabled"
}

variable "idrepo_startup_probe_initial_delay" {
  description = "Initial delay for startup probe in IDREPO"
  type        = number
  default     = 90
}

variable "idrepo_startup_probe_timeout" {
  description = "Timeout for startup probe in IDREPO"
  type        = number
  default     = 180
}

variable "idrepo_helm_timeout_seconds" {
  description = "Timeout in seconds for IDREPO Helm operations"
  type        = number
  default     = 1200
}

# PMS Variables
variable "pms_enabled" {
  description = "Flag to enable/disable PMS module"
  type        = bool
  default     = true
}

variable "pms_namespace" {
  description = "Namespace for PMS module"
  type        = string
  default     = "pms"
}

variable "pms_helm_chart_version" {
  description = "Helm chart version for PMS"
  type        = string
  default     = "12.0.1"
}

variable "pmp_ui_chart_version" {
  description = "Helm chart version for PMP UI"
  type        = string
  default     = "12.0.1"
}

variable "pms_istio_injection_label" {
  description = "Istio injection label for PMS namespace"
  type        = string
  default     = "enabled"
}

variable "pms_startup_probe_initial_delay" {
  description = "Initial delay for startup probe in PMS"
  type        = number
  default     = 90
}

variable "pms_startup_probe_timeout" {
  description = "Timeout for startup probe in PMS"
  type        = number
  default     = 180
}

variable "pms_helm_timeout_seconds" {
  description = "Timeout in seconds for PMS Helm operations"
  type        = number
  default     = 1200
}

# Mock ABIS Variables
variable "mock_abis_enabled" {
  description = "Flag to enable/disable Mock ABIS component"
  type        = bool
  default     = true
}

variable "mock_mv_enabled" {
  description = "Flag to enable/disable Mock MV component"
  type        = bool
  default     = false
}

variable "mock_abis_namespace" {
  description = "Namespace for Mock ABIS and Mock MV components"
  type        = string
  default     = "abis"
}

variable "mock_abis_helm_chart_version" {
  description = "Helm chart version for Mock ABIS"
  type        = string
  default     = "12.0.2"
}

variable "mock_mv_helm_chart_version" {
  description = "Helm chart version for Mock MV"
  type        = string
  default     = "12.0.2"
}

variable "mock_abis_istio_injection_label" {
  description = "Istio injection label for Mock ABIS namespace"
  type        = string
  default     = "enabled"
}

variable "mock_abis_startup_probe_initial_delay" {
  description = "Initial delay for startup probe in Mock ABIS"
  type        = number
  default     = 90
}

variable "mock_abis_startup_probe_timeout" {
  description = "Timeout for startup probe in Mock ABIS"
  type        = number
  default     = 180
}

variable "mock_abis_helm_timeout_seconds" {
  description = "Timeout in seconds for Mock ABIS Helm operations"
  type        = number
  default     = 1200
}


variable "mock_mv_istio_injection_label" {
  description = "Istio injection label for Mock MV namespace"
  type        = string
  default     = "enabled"
}

variable "mock_mv_startup_probe_initial_delay" {
  description = "Initial delay for startup probe in Mock MV"
  type        = number
  default     = 90
}

variable "mock_mv_startup_probe_timeout" {
  description = "Timeout for startup probe in Mock MV"
  type        = number
  default     = 180
}

variable "mock_mv_helm_timeout_seconds" {
  description = "Timeout in seconds for Mock MV Helm operations"
  type        = number
  default     = 1200
}

variable "regproc_enabled" {
  description = "Flag to enable/disable regproc module"
  type        = bool
  default     = true
}

variable "regproc_namespace" {
  description = "Namespace for regproc"
  type        = string
  default     = "regproc"
}

variable "regproc_helm_chart_version" {
  description = "Helm chart version for regproc"
  type        = string
  default     = "12.0.1"
}

variable "admin_enabled" {
  description = "Flag to enable/disable admin module"
  type        = bool
  default     = true
}

variable "admin_namespace" {
  description = "Namespace for admin"
  type        = string
  default     = "admin"
}

variable "admin_helm_chart_version" {
  description = "Helm chart version for admin"
  type        = string
  default     = "12.0.1"
}

variable "ida_enabled" {
  description = "Flag to enable/disable ida module"
  type        = bool
  default     = true
}

variable "ida_namespace" {
  description = "Namespace for ida"
  type        = string
  default     = "ida"
}

variable "ida_helm_chart_version" {
  description = "Helm chart version for ida"
  type        = string
  default     = "12.0.1"
}

variable "ida_enable_insecure" {
  description = "Flag to enable insecure mode for development environments in ida"
  type        = bool
  default     = false
}

# Print Configuration
variable "print_enabled" {
  description = "Flag to enable/disable print module"
  type        = bool
  default     = true
}

variable "print_namespace" {
  description = "Namespace for print"
  type        = string
  default     = "print"
}

variable "print_helm_chart_version" {
  description = "Helm chart version for print"
  type        = string
  default     = "12.0.1"
}

# Resident Configuration
variable "resident_enabled" {
  description = "Flag to enable/disable resident module"
  type        = bool
  default     = true
}

variable "resident_namespace" {
  description = "Namespace for resident"
  type        = string
  default     = "resident"
}

variable "resident_helm_chart_version" {
  description = "Helm chart version for resident"
  type        = string
  default     = "12.0.1"
}

variable "resident_ui_chart_version" {
  description = "Helm chart version for resident UI"
  type        = string
  default     = "0.0.1"
}

variable "resident_enable_insecure" {
  description = "Enable insecure mode for development environments in resident"
  type        = bool
  default     = false
}

# Partner Onboarder Configuration
variable "partner_onboarder_enabled" {
  description = "Flag to enable/disable partner-onboarder module"
  type        = bool
  default     = true
}

variable "partner_onboarder_namespace" {
  description = "Namespace for partner-onboarder"
  type        = string
  default     = "partner-onboarder"
}

variable "partner_onboarder_helm_chart_version" {
  description = "Helm chart version for partner-onboarder"
  type        = string
  default     = "12.0.1"
}

variable "partner_onboarder_s3_bucket_name" {
  description = "S3/MinIO bucket name for partner onboarder"
  type        = string
  default     = "mosip-partner-onboarder"
}

variable "regproc_helm_timeout" {
  description = "Timeout for Helm operations in regproc module (seconds)"
  type        = number
  default     = 1200
}

variable "admin_helm_timeout" {
  description = "Timeout for Helm operations in admin module (seconds)"
  type        = number
  default     = 1200
}

variable "resident_helm_timeout" {
  description = "Timeout for Helm operations in resident module (seconds)"
  type        = number
  default     = 1200
}

variable "print_helm_timeout" {
  description = "Timeout for Helm operations in print module (seconds)"
  type        = number
  default     = 1200
}

variable "partner_onboarder_helm_timeout" {
  description = "Timeout for Helm operations in partner-onboarder module (seconds)"
  type        = number
  default     = 1200
}

variable "mosip_file_server_helm_timeout" {
  description = "Timeout for Helm operations in mosip-file-server module (seconds)"
  type        = number
  default     = 1200
}

variable "ida_helm_timeout" {
  description = "Timeout for Helm operations in ida module (seconds)"
  type        = number
  default     = 1200
}

variable "mosip_file_server_enabled" {
  description = "Flag to enable/disable mosip-file-server module"
  type        = bool
  default     = true
}

variable "mosip_file_server_namespace" {
  description = "Namespace for mosip-file-server"
  type        = string
  default     = "mosip-file-server"
}

variable "mosip_file_server_helm_chart_version" {
  description = "Helm chart version for mosip-file-server"
  type        = string
  default     = "12.0.1"
}

# Regclient Configuration
variable "regclient_enabled" {
  description = "Flag to enable/disable regclient module"
  type        = bool
  default     = true
}

variable "regclient_namespace" {
  description = "Namespace for regclient"
  type        = string
  default     = "regclient"
}

variable "regclient_helm_chart_version" {
  description = "Helm chart version for regclient"
  type        = string
  default     = "12.0.2"
}

variable "regclient_startup_probe_timeout" {
  description = "Timeout seconds for startup probe in regclient"
  type        = number
  default     = 180
}

variable "regclient_startup_probe_initial_delay" {
  description = "Initial delay seconds for startup probe in regclient"
  type        = number
  default     = 90
}