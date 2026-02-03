# Create namespace
resource "kubernetes_namespace" "regclient" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Define source configmaps
data "kubernetes_config_map" "global" {
  metadata {
    name      = "global"
    namespace = "default"
  }
}

data "kubernetes_config_map" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = "artifactory"
  }
}

# Generate random bytes and convert to base64 to match original openssl behavior
resource "random_id" "keystore_pwd" {
  count       = var.keystore_password == "" ? 1 : 0
  byte_length = 10
}

locals {
  keystore_pwd = var.keystore_password != "" ? var.keystore_password : random_id.keystore_pwd[0].b64_std
}

# Create keystore secret
resource "kubernetes_secret_v1" "keystore_secret_env" {
  metadata {
    name      = "keystore-secret-env"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }

  data = {
    "keystore_secret_env" = local.keystore_pwd
  }

  depends_on = [kubernetes_namespace.regclient]
}

# Generate certificates and create configmap using kubectl
resource "null_resource" "generate_certs" {
  triggers = {
    keystore_pwd = local.keystore_pwd
    # Force regeneration if the namespace is recreated (clean install)
    namespace_id = kubernetes_namespace.regclient.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      rm -rf ./certs
      mkdir -p ./certs
      
      # Generate CA certificate
      openssl genrsa -out ./certs/RootCA.key 4096
      openssl req -new -x509 -days 1826 -key ./certs/RootCA.key -out ./certs/RootCA.crt -config ./templates/root-openssl.cnf
      
      # Generate client certificate
      openssl genrsa -out ./certs/Client.key 4096
      openssl req -new -key ./certs/Client.key -out ./certs/Client.csr -config ./templates/client-openssl.cnf
      openssl x509 -req -extensions v3_req -extfile ./templates/client-openssl.cnf -days 1826 -in ./certs/Client.csr -CA ./certs/RootCA.crt -CAkey ./certs/RootCA.key -set_serial 01 -out ./certs/Client.crt
      openssl verify -CAfile ./certs/RootCA.crt ./certs/Client.crt
      
      # Export to PKCS12 with legacy compatibility flags for Java 11/17 
      # and explicitly specify the password to avoid shell expansion issues
      openssl pkcs12 -export -in ./certs/Client.crt -inkey ./certs/Client.key \
        -out ./certs/keystore.p12 -name "CodeSigning" \
        -passout "pass:${local.keystore_pwd}" \
        -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg SHA1
      
      # Create configmap using kubectl (delete first if exists to ensure idempotency)
      kubectl -n ${kubernetes_namespace.regclient.metadata[0].name} delete cm regclient-certs --ignore-not-found=true
      kubectl -n ${kubernetes_namespace.regclient.metadata[0].name} create cm regclient-certs --from-file=./certs/
    EOT
  }

  depends_on = [kubernetes_namespace.regclient, kubernetes_secret_v1.keystore_secret_env]
}

# Copy configmaps to regclient namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.regclient,null_resource.generate_certs]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.regclient,null_resource.generate_certs]
}

# Deploy regclient
resource "helm_release" "regclient" {
  name       = "regclient"
  chart      = "regclient"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regclient.metadata[0].name
  timeout    = var.helm_timeout_seconds

  set {
    name  = "regclient.upgradeServerUrl"
    value = "https://${data.kubernetes_config_map.global.data["mosip-regclient-host"]}"
  }

  set {
    name  = "regclient.healthCheckUrl"
    value = "https://${data.kubernetes_config_map.global.data["mosip-api-internal-host"]}/v1/syncdata/actuator/health"
  }

  set {
    name  = "regclient.hostName"
    value = data.kubernetes_config_map.global.data["mosip-api-internal-host"]
  }

  set {
    name  = "istio.host"
    value = data.kubernetes_config_map.global.data["mosip-regclient-host"]
  }

  set {
    name  = "startupProbe.enabled"
    value = tostring(var.startup_probe_enabled)
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = tostring(var.startup_probe_timeout_seconds)
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = tostring(var.startup_probe_initial_delay_seconds)
  }

  set {
    name  = "startupProbe.periodSeconds"
    value = tostring(var.startup_probe_period_seconds)
  }

  set {
    name  = "startupProbe.failureThreshold"
    value = tostring(var.startup_probe_failure_threshold)
  }

  set {
    name  = "readinessProbe.enabled"
    value = tostring(var.readiness_probe_enabled)
  }

  set {
    name  = "readinessProbe.timeoutSeconds"
    value = tostring(var.readiness_probe_timeout_seconds)
  }

  set {
    name  = "readinessProbe.initialDelaySeconds"
    value = tostring(var.readiness_probe_initial_delay_seconds)
  }

  set {
    name  = "readinessProbe.periodSeconds"
    value = tostring(var.readiness_probe_period_seconds)
  }

  set {
    name  = "readinessProbe.failureThreshold"
    value = tostring(var.readiness_probe_failure_threshold)
  }

  set {
    name  = "livenessProbe.enabled"
    value = tostring(var.liveness_probe_enabled)
  }

  set {
    name  = "livenessProbe.timeoutSeconds"
    value = tostring(var.liveness_probe_timeout_seconds)
  }

  set {
    name  = "livenessProbe.initialDelaySeconds"
    value = tostring(var.liveness_probe_initial_delay_seconds)
  }

  set {
    name  = "livenessProbe.periodSeconds"
    value = tostring(var.liveness_probe_period_seconds)
  }

  set {
    name  = "livenessProbe.failureThreshold"
    value = tostring(var.liveness_probe_failure_threshold)
  }

  # Force restart of pods if keystore password changes
  set {
    name  = "config.keystoreChecksum"
    value = sha256(local.keystore_pwd)
  }

  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_secret_v1.keystore_secret_env,
    null_resource.generate_certs
  ]
} 