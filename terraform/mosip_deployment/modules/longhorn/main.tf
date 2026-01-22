# Deploy Longhorn using Helm
resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode({
      persistence = {
        defaultClass = true
        defaultClassReplicaCount = var.replica_count
      }
      defaultSettings = {
        defaultReplicaCount = var.replica_count
        guaranteedEngineManagerCPU = var.guaranteed_engine_cpu
        guaranteedReplicaManagerCPU = var.guaranteed_replica_cpu
        storageMinimalAvailablePercentage = var.storage_minimal_available_percentage
        storageOverProvisioningPercentage = var.storage_over_provisioning_percentage
        storageReservedPercentage = var.storage_reserved_percentage
        autoSalvage = var.auto_salvage
        autoDeletePodWhenVolumeDetachedUnexpectedly = var.auto_delete_pod_when_volume_detached_unexpectedly
        disableSchedulingOnCordonedNode = var.disable_scheduling_on_cordoned_node
        replicaZoneSoftAntiAffinity = var.replica_zone_soft_anti_affinity
        createDefaultDiskLabeledStorage = true
        defaultDataPath = "/var/lib/longhorn/"
      }
    })
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 600
}

# Wait for CSI deployments to be ready
resource "time_sleep" "wait_for_csi" {
  depends_on = [helm_release.longhorn]
  create_duration = "60s"
}

# Verify CSI deployments
data "kubernetes_resources" "csi_deployments" {
  api_version = "apps/v1"
  kind        = "Deployment"
  namespace   = var.namespace

  depends_on = [time_sleep.wait_for_csi]
}

locals {
  required_deployments = ["csi-attacher", "csi-provisioner", "csi-resizer", "csi-snapshotter", "longhorn-driver-deployer"]
  deployment_ready = {
    for deployment in local.required_deployments :
    deployment => contains([for d in data.kubernetes_resources.csi_deployments.objects : d.metadata.name], deployment) &&
    try(
      [for d in data.kubernetes_resources.csi_deployments.objects : d.status.ready_replicas if d.metadata.name == deployment][0] > 0,
      false
    )
  }
} 