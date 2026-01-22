#output "longhorn_release" {
#  description = "The Longhorn Helm release"
#  value       = var.longhorn_enable ? module.longhorn.longhorn_release : null
#}

output "csi_deployment_status" {
  description = "Status of CSI deployments"
  value       = var.longhorn_enable ? module.longhorn.csi_deployment_status : null
}

output "istio_status" {
  description = "Status of Istio deployment"
  value = var.enable_istio ? {
    namespace = module.istio.namespace
    ingress_gateway = module.istio.ingress_gateway_service
  } : null
}

output "activemq_namespace" {
  description = "Namespace where ActiveMQ is deployed"
  value       = var.enable_activemq ? module.activemq[0].namespace : null
}

output "kafka_namespace" {
  description = "Namespace where Kafka is deployed"
  value       = var.enable_kafka ? module.kafka[0].namespace : null
}

output "kafka_ui_url" {
  description = "URL for accessing Kafka UI"
  value       = var.enable_kafka ? "https://kafka.${var.installation_domain}" : null
}

output "clamav_namespace" {
  description = "The Kubernetes namespace where ClamAV is deployed"
  value       = var.enable_clamav ? module.clamav[0].namespace : null
}

output "clamav_helm_release_name" {
  description = "The name of the Helm release for ClamAV"
  value       = var.enable_clamav ? module.clamav[0].helm_release_name : null
}

output "clamav_helm_release_version" {
  description = "The version of the Helm release for ClamAV"
  value       = var.enable_clamav ? module.clamav[0].helm_release_version : null
}

# MSG Gateway Outputs
output "msg_gateway_namespace" {
  description = "The namespace where msg-gateway resources are deployed"
  value       = var.msg_gateway_enabled ? module.msg_gateway[0].namespace : null
}

output "docker_secrets_status" {
  description = "Status of docker registry secrets"
  value = var.docker_secrets_enabled ? {
    enabled = true
    secrets = module.docker_secrets[0].docker_secret
    namespace = null
  } : {
    enabled = false
    secrets = null
    namespace = null
  }
}

output "docker_secrets_namespace" {
  description = "Namespace where docker secrets is deployed"
  value       = var.docker_secrets_enabled ? module.docker_secrets[0].namespace : null
}

output "docker_secrets_is_installed" {
  description = "Whether docker secrets is installed"
  value       = var.docker_secrets_enabled ? module.docker_secrets[0].is_installed : false
}

output "conf_secrets_namespace" {
  description = "Namespace where conf secrets is deployed"
  value       = var.conf_secrets_enabled ? module.conf_secrets[0].namespace : null
}

output "conf_secrets_is_installed" {
  description = "Whether conf secrets is installed"
  value       = var.conf_secrets_enabled ? module.conf_secrets[0].is_installed : false
}

output "config_server_namespace" {
  description = "Namespace where config-server is deployed"
  value       = var.config_server_enabled ? module.config_server[0].namespace : null
}

output "config_server_is_installed" {
  description = "Whether config-server is installed"
  value       = var.config_server_enabled ? module.config_server[0].is_installed : false
}

output "config_server_helm_release" {
  description = "Name of the config-server Helm release"
  value       = var.config_server_enabled ? module.config_server[0].helm_release_name : null
}

output "s3_credentials_status" {
  description = "Status of S3 credentials configuration"
  value = var.create_s3_namespace ? {
    namespace = "s3"
    enabled = true
    using_minio = var.use_existing_minio
  } : {
    namespace = null
    enabled = false
    using_minio = false
  }
}

output "landing_page" {
  description = "Landing Page deployment details"
  value = var.enable_landing_page ? {
    namespace          = module.landing_page[0].namespace
    helm_release       = module.landing_page[0].helm_release_status
  } : null
}

output "captcha_namespace" {
  description = "Namespace where captcha resources are deployed"
  value       = var.enable_captcha ? module.captcha[0].namespace : ""
}

output "captcha_secret_name" {
  description = "Name of the captcha secret"
  value       = var.enable_captcha ? module.captcha[0].secret_name : ""
}

output "artifactory_namespace" {
  description = "Namespace where artifactory is deployed"
  value       = var.artifactory_enable ? module.artifactory[0].namespace : null
}

output "artifactory_is_installed" {
  description = "Whether artifactory is installed"
  value       = var.artifactory_enable ? module.artifactory[0].is_installed : false
}

output "artifactory_helm_release" {
  description = "Name of the artifactory Helm release"
  value       = var.artifactory_enable ? module.artifactory[0].helm_release_name : null
}

# Keymanager outputs
output "keymanager_namespace" {
  description = "The namespace where keymanager is deployed"
  value       = var.enable_keymanager ? module.keymanager[0].namespace : null
}

output "keymanager_is_installed" {
  description = "Whether keymanager is installed"
  value       = var.enable_keymanager ? module.keymanager[0].is_installed : false
}

output "keymanager_helm_release_name" {
  description = "Name of the keymanager Helm release"
  value       = var.enable_keymanager ? module.keymanager[0].helm_release_name : null
}

output "keymanager_helm_release_version" {
  description = "Version of the keymanager Helm release"
  value       = var.enable_keymanager ? module.keymanager[0].helm_release_version : null
}

output "keymanager_keygen_release_name" {
  description = "Name of the keygen Helm release"
  value       = var.enable_keymanager ? module.keymanager[0].keygen_release_name : null
}

output "keymanager_keygen_release_version" {
  description = "Version of the keygen Helm release"
  value       = var.enable_keymanager ? module.keymanager[0].keygen_release_version : null
}

output "websub_namespace" {
  description = "Namespace where websub is deployed"
  value       = var.websub_enabled ? module.websub[0].namespace : null
}

output "websub_consolidator_status" {
  description = "Status of websub consolidator deployment"
  value       = var.websub_enabled ? module.websub[0].websub_consolidator_status : null
}

output "websub_status" {
  description = "Status of websub deployment"
  value       = var.websub_enabled ? module.websub[0].websub_status : null
}

output "mock_smtp_namespace" {
  value = var.mock_smtp_enabled ? module.mock_smtp[0].namespace : null
}

output "mock_smtp_helm_release_status" {
  value = var.mock_smtp_enabled ? module.mock_smtp[0].helm_release_status : null
}

output "kernel_namespace" {
  description = "Namespace where kernel components are deployed"
  value       = var.kernel_enabled ? module.kernel[0].namespace : null
}

output "kernel_authmanager_status" {
  description = "Status of kernel authmanager deployment"
  value       = var.kernel_enabled ? module.kernel[0].authmanager_status : null
}

output "kernel_auditmanager_status" {
  description = "Status of kernel auditmanager deployment"
  value       = var.kernel_enabled ? module.kernel[0].auditmanager_status : null
}

output "kernel_idgenerator_status" {
  description = "Status of kernel idgenerator deployment"
  value       = var.kernel_enabled ? module.kernel[0].idgenerator_status : null
}

output "kernel_masterdata_status" {
  description = "Status of kernel masterdata deployment"
  value       = var.kernel_enabled ? module.kernel[0].masterdata_status : null
}

output "kernel_otpmanager_status" {
  description = "Status of kernel otpmanager deployment"
  value       = var.kernel_enabled ? module.kernel[0].otpmanager_status : null
}

output "kernel_pridgenerator_status" {
  description = "Status of kernel pridgenerator deployment"
  value       = var.kernel_enabled ? module.kernel[0].pridgenerator_status : null
}

output "kernel_ridgenerator_status" {
  description = "Status of kernel ridgenerator deployment"
  value       = var.kernel_enabled ? module.kernel[0].ridgenerator_status : null
}

output "kernel_syncdata_status" {
  description = "Status of kernel syncdata deployment"
  value       = var.kernel_enabled ? module.kernel[0].syncdata_status : null
}

output "kernel_notifier_status" {
  description = "Status of kernel notifier deployment"
  value       = var.kernel_enabled ? module.kernel[0].notifier_status : null
}

output "masterdata_loader_namespace" {
  description = "Namespace where masterdata-loader is deployed"
  value       = var.masterdata_loader_enabled ? module.masterdata_loader[0].namespace : null
}

output "masterdata_loader_helm_release_status" {
  description = "Status of masterdata-loader helm release"
  value       = var.masterdata_loader_enabled ? module.masterdata_loader[0].helm_release_status : null
}

output "biosdk_namespace" {
  description = "Namespace where biosdk is deployed"
  value       = var.biosdk_enabled ? module.biosdk[0].namespace : null
}

output "biosdk_status" {
  description = "Status of biosdk deployment"
  value       = var.biosdk_enabled ? module.biosdk[0].biosdk_service_status : null
}

output "packetmanager_namespace" {
  description = "Namespace where packetmanager is deployed"
  value       = var.packetmanager_enabled ? module.packetmanager[0].namespace : null
}

output "packetmanager_status" {
  description = "Status of packetmanager deployment"
  value       = var.packetmanager_enabled ? module.packetmanager[0].packetmanager_status : null
}

output "datashare_namespace" {
  description = "Namespace where datashare is deployed"
  value       = var.datashare_enabled ? module.datashare[0].namespace : null
}

output "datashare_status" {
  description = "Status of datashare deployment"
  value       = var.datashare_enabled ? module.datashare[0].datashare_status : null
}

output "prereg_namespace" {
  description = "Namespace where prereg is deployed"
  value       = var.prereg_enabled ? module.prereg[0].namespace : null
}

output "prereg_gateway_status" {
  description = "Status of prereg gateway deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_gateway_status : null
}

output "prereg_captcha_status" {
  description = "Status of prereg captcha deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_captcha_status : null
}

output "prereg_application_status" {
  description = "Status of prereg application deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_application_status : null
}

output "prereg_booking_status" {
  description = "Status of prereg booking deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_booking_status : null
}

output "prereg_datasync_status" {
  description = "Status of prereg datasync deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_datasync_status : null
}

output "prereg_batchjob_status" {
  description = "Status of prereg batchjob deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_batchjob_status : null
}

output "prereg_ui_status" {
  description = "Status of prereg ui deployment"
  value       = var.prereg_enabled ? module.prereg[0].prereg_ui_status : null
}

# IDREPO outputs
output "idrepo_namespace" {
  description = "Namespace where IDREPO is deployed"
  value       = var.idrepo_enabled ? module.idrepo[0].namespace : null
}

output "idrepo_status" {
  description = "Status of IDREPO deployment"
  value       = var.idrepo_enabled ? module.idrepo[0].idrepo_status : null
}

# PMS outputs
output "pms_namespace" {
  description = "Namespace where PMS is deployed"
  value       = var.pms_enabled ? module.pms[0].namespace : null
}

output "pms_status" {
  description = "Status of PMS deployment"
  value       = var.pms_enabled ? module.pms[0].pms_status : null
}

# Mock ABIS outputs
output "mock_abis_namespace" {
  description = "The namespace where mock services are deployed"
  value       = var.mock_abis_enabled || var.mock_mv_enabled ? module.mock_abis[0].namespace : null
}

output "mock_abis_status" {
  description = "Status of mock-abis deployment"
  value       = var.mock_abis_enabled ? module.mock_abis[0].mock_abis_status : null
}

output "mock_mv_status" {
  description = "Status of mock-mv deployment"
  value       = var.mock_mv_enabled ? module.mock_abis[0].mock_mv_status : null
}

output "regproc_namespace" {
  description = "Namespace where regproc is installed"
  value       = var.regproc_enabled ? module.regproc[0].namespace : null
}

output "admin_namespace" {
  description = "Namespace where admin is installed"
  value       = var.admin_enabled ? module.admin[0].namespace : null
}

output "admin_ui_url" {
  description = "The URL for accessing the admin UI"
  value       = var.admin_enabled ? module.admin[0].admin_ui_url : null
}

output "ida_namespace" {
  description = "Namespace where ida is installed"
  value       = var.ida_enabled ? module.ida[0].namespace : null
}

output "print_namespace" {
  description = "Namespace where print is installed"
  value       = var.print_enabled ? module.print[0].namespace : null
}

output "print_service_status" {
  description = "Status of print service deployment"
  value       = var.print_enabled ? module.print[0].print_service_status : null
  sensitive   = true
}

# Resident outputs
output "resident_namespace" {
  description = "Namespace where resident is installed"
  value       = var.resident_enabled ? module.resident[0].namespace : null
}

output "resident_status" {
  description = "Status of resident deployment"
  value       = var.resident_enabled ? module.resident[0].resident_status : null
}

output "resident_ui_status" {
  description = "Status of resident UI deployment"
  value       = var.resident_enabled ? module.resident[0].resident_ui_status : null
}

output "resident_ui_url" {
  description = "URL for accessing resident UI"
  value       = var.resident_enabled ? module.resident[0].resident_ui_url : null
}

# Regclient outputs
output "regclient_namespace" {
  description = "Namespace where regclient is installed"
  value       = var.regclient_enabled ? module.regclient[0].namespace : null
}

output "regclient_status" {
  description = "Status of regclient deployment"
  value       = var.regclient_enabled ? module.regclient[0].regclient_status : null
}

output "regclient_url" {
  description = "URL for accessing regclient"
  value       = var.regclient_enabled ? module.regclient[0].regclient_url : null
}

output "partner_onboarder_namespace" {
  description = "Namespace where partner-onboarder is installed"
  value       = var.partner_onboarder_enabled ? module.partner_onboarder[0].namespace : null
}

output "partner_onboarder_status" {
  description = "Status of partner-onboarder deployment"
  value       = var.partner_onboarder_enabled ? module.partner_onboarder[0].partner_onboarder_status : null
  sensitive   = true
}


output "iam_status" {
  description = "Status of IAM deployment"
  value = var.iam_enable ? {
    namespace = module.iam[0].namespace
    keycloak_status = module.iam[0].keycloak_status
    keycloak_init_status = module.iam[0].keycloak_init_status
    admin_url = "https://iam.${var.installation_domain}/auth"
    smtp_configured = module.iam[0].smtp_configured
  } : null
}