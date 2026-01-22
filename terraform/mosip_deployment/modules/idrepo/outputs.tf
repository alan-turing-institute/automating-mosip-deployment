output "namespace" {
  description = "The namespace where idrepo is deployed"
  value       = kubernetes_namespace.idrepo.metadata[0].name
}

output "idrepo_status" {
  description = "Status of IDREPO deployment"
  value = {
    saltgen_status = helm_release.idrepo_saltgen.status
    credential_status = helm_release.credential.status
    credentialrequest_status = helm_release.credentialrequest.status
    identity_status = helm_release.identity.status
    vid_status = helm_release.vid.status
  }
} 