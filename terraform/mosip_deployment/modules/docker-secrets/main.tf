resource "kubernetes_secret" "docker_registry" {
  count = var.docker_secrets_enabled ? 1 : 0

  metadata {
    name = "regsecret"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.docker_registry_url}" = {
          auth = base64encode("${var.docker_username}:${var.docker_password}")
          email = var.docker_email
        }
      }
    })
  }
}

output "docker_secret" {
  description = "Created docker registry secret details"
  value = var.docker_secrets_enabled ? {
    name = kubernetes_secret.docker_registry[0].metadata[0].name
  } : null
}