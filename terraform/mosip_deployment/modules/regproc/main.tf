resource "kubernetes_namespace" "regproc" {
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

data "kubernetes_config_map" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = "config-server"
  }
}

# Create configmaps in prereg namespace
resource "kubernetes_config_map_v1" "global" {
  metadata {
    name      = "global"
    namespace = kubernetes_namespace.regproc.metadata[0].name
  }

  data = data.kubernetes_config_map.global.data

  depends_on = [kubernetes_namespace.regproc]
}

resource "kubernetes_config_map_v1" "artifactory_share" {
  metadata {
    name      = "artifactory-share"
    namespace = kubernetes_namespace.regproc.metadata[0].name
  }

  data = data.kubernetes_config_map.artifactory_share.data

  depends_on = [kubernetes_namespace.regproc]
}

resource "kubernetes_config_map_v1" "config_server_share" {
  metadata {
    name      = "config-server-share"
    namespace = kubernetes_namespace.regproc.metadata[0].name
  }

  data = data.kubernetes_config_map.config_server_share.data

  depends_on = [kubernetes_namespace.regproc]
}




# Install regproc-group1
resource "helm_release" "regproc_group1" {
  name       = "regproc-group1"
  chart      = "mosip/regproc-group1"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]

  set {
    name  = "persistence.storageClass"
    value = "longhorn"
  }

  set {
    name  = "persistence.size"
    value = "5Gi"
  }

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = var.helm_timeout
}

# Install regproc-group2
resource "helm_release" "regproc_group2" {
  name       = "regproc-group2"
  chart      = "mosip/regproc-group2"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]
  
  # TODO: Disable startup probe as a workaround for the crash
  set {
    name  = "startupProbe.enabled"
    value = false
  }
  set {
    name  = "readinessProbe.enabled"
    value = false
  }

#  set {
#    name  = "startupProbe.timeoutSeconds"
#    value = "180"
#  }
#
#  set {
#    name  = "startupProbe.initialDelaySeconds"
#    value = "600"
#  }
  
  timeout = 1500
}

# Install regproc-group3
resource "helm_release" "regproc_group3" {
  name       = "regproc-group3"
  chart      = "mosip/regproc-group3"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-group4
resource "helm_release" "regproc_group4" {
  name       = "regproc-group4"
  chart      = "mosip/regproc-group4"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-group5
resource "helm_release" "regproc_group5" {
  name       = "regproc-group5"
  chart      = "mosip/regproc-group5"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-group6
resource "helm_release" "regproc_group6" {
  name       = "regproc-group6"
  chart      = "mosip/regproc-group6"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-group7
resource "helm_release" "regproc_group7" {
  name       = "regproc-group7"
  chart      = "mosip/regproc-group7"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-salt
resource "helm_release" "regproc_salt" {
  name       = "regproc-salt"
  chart      = "mosip/regproc-salt"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-workflow
resource "helm_release" "regproc_workflow" {
  name       = "regproc-workflow"
  chart      = "mosip/regproc-workflow"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]

  # TODO: Disable startup probe as a workaround for the crash
  set {
    name  = "startupProbe.enabled"
    value = false
  }
  set {
    name  = "readinessProbe.enabled"
    value = false
  }
  set {
    name  = "livenessProbe.enabled"
    value = false
  }

#  set {
#    name  = "startupProbe.timeoutSeconds"
#    value = "180"
#  }
#
#  set {
#    name  = "startupProbe.initialDelaySeconds"
#    value = "600"
#  }

  timeout = 1500
}

# Install regproc-status
resource "helm_release" "regproc_status" {
  name       = "regproc-status"
  chart      = "mosip/regproc-status"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]
  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-camel
resource "helm_release" "regproc_camel" {
  name       = "regproc-camel"
  chart      = "mosip/regproc-camel"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-pktserver
resource "helm_release" "regproc_pktserver" {
  name       = "regproc-pktserver"
  chart      = "mosip/regproc-pktserver"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}
# Install regproc-trans
resource "helm_release" "regproc_trans" {
  name       = "regproc-trans"
  chart      = "mosip/regproc-trans"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-notifier
resource "helm_release" "regproc_notifier" {
  name       = "regproc-notifier"
  chart      = "mosip/regproc-notifier"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}

# Install regproc-reprocess
resource "helm_release" "regproc_reprocess" {
  name       = "regproc-reprocess"
  chart      = "mosip/regproc-reprocess"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.regproc.metadata[0].name
  depends_on = [
    kubernetes_config_map_v1.global,
    kubernetes_config_map_v1.artifactory_share,
    kubernetes_config_map_v1.config_server_share,
    helm_release.regproc_salt,
    helm_release.regproc_group1,
    helm_release.regproc_group2,
    helm_release.regproc_group3,
    helm_release.regproc_group4,
    helm_release.regproc_group5,
    helm_release.regproc_group6,
    helm_release.regproc_group7
  ]

  set {
    name  = "startupProbe.timeoutSeconds"
    value = "180"
  }

  set {
    name  = "startupProbe.initialDelaySeconds"
    value = "600"
  }

  timeout = 1500
}


## Install regproc-landingzone
# Currently NOT IN USE - ITS PUSHED FROM DEV image with errors
#resource "helm_release" "regproc_landingzone" {
#  name       = "regproc-landingzone"
#  chart      = "mosip/regproc-landingzone"
#  version    = "12.0.2" # No longer 12.0.1 in helm repo
#  namespace  = kubernetes_namespace.regproc.metadata[0].name
#  depends_on = [
#    kubernetes_config_map_v1.global,
#    kubernetes_config_map_v1.artifactory_share,
#    kubernetes_config_map_v1.config_server_share,
#    helm_release.regproc_salt,
#    helm_release.regproc_group1,
#    helm_release.regproc_group2,
#    helm_release.regproc_group3,
#    helm_release.regproc_group4,
#    helm_release.regproc_group5,
#    helm_release.regproc_group6,
#    helm_release.regproc_group7
#  ]
#
#  # TODO: Disable startup probe as a workaround for the crash
#  set {
#    name  = "startupProbe.enabled"
#    value = false
#  }
#  set {
#    name  = "readinessProbe.enabled"
#    value = false
#  }
#
##  set {
##    name  = "startupProbe.timeoutSeconds"
##    value = "180"
##  }
##
##  set {
##    name  = "startupProbe.initialDelaySeconds"
##    value = "600"
##  }
#
#  timeout = 1500
#} 