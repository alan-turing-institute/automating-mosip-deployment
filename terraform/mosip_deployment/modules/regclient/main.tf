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

# Generate base64 keystore password
resource "null_resource" "generate_pwd" {
  provisioner "local-exec" {
    command = "openssl rand -base64 10 > ${path.module}/keystore_pwd"
  }
}

data "local_file" "keystore_pwd" {
  filename = "${path.module}/keystore_pwd"
  depends_on = [null_resource.generate_pwd]
}

# Create keystore secret
resource "kubernetes_secret_v1" "keystore_secret_env" {
  metadata {
    name      = "keystore-secret-env"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }

  data = {
    "keystore_secret_env" = trimspace(data.local_file.keystore_pwd.content)
  }

  depends_on = [kubernetes_namespace.regclient]
}

# Generate certificates and create configmap using kubectl
resource "null_resource" "generate_certs" {
  triggers = {
    keystore_pwd = data.local_file.keystore_pwd.content
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
      openssl pkcs12 -export -in ./certs/Client.crt -inkey ./certs/Client.key -out ./certs/keystore.p12 -name "CodeSigning" -password pass:${trimspace(data.local_file.keystore_pwd.content)}
      
      # Create configmap using kubectl
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

  depends_on = [kubernetes_namespace.regclient]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.regclient.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.regclient]
}

# Deploy regclient
resource "helm_release" "regclient" {
  name       = "regclient"
  chart      = "regclient"
  repository = "mosip"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regclient.metadata[0].name
  timeout    = 1200 # 20 minutes

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
    name  = "startupProbe.timeoutSeconds"
    value = var.startup_probe_timeout
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = var.startup_probe_initial_delay
  }

  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_secret_v1.keystore_secret_env,
    null_resource.generate_certs
  ]
} 