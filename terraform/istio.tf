resource "helm_release" "istio_base" {
  name            = "istio-base"
  repository      = "https://istio-release.storage.googleapis.com/charts"
  chart           = "base"
  namespace       = var.istio_namespace
  version         = var.istio_version
  create_namespace = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode({
      global = {
        jwtPolicy = "third-party-jwt"
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.istio_namespaces
  ]
}

resource "helm_release" "istio_discovery" {
  name            = "istiod"
  repository      = "https://istio-release.storage.googleapis.com/charts"
  chart           = "istiod"
  namespace       = var.istio_namespace
  version         = var.istio_version
  create_namespace = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode({
      global = {
        jwtPolicy = "third-party-jwt"
      }
      pilot = {
        autoscalingv2Enabled = true
        replicaCount         = 1
        resources = {
          requests = {
            cpu    = "100m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "2048Mi"
          }
        }
      }
      telemetry = {
        enabled = true
      }
    })
  ]

  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istio_ingressgateway" {
  name            = "istio-ingressgateway"
  repository      = "https://istio-release.storage.googleapis.com/charts"
  chart           = "gateway"
  namespace       = var.istio_namespace
  version         = var.istio_version
  create_namespace = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode({
      replicaCount = 2
      service = {
        type = "LoadBalancer"
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      autoscaling = {
        enabled     = true
        minReplicas = 2
        maxReplicas = 5
        targetCPUUtilizationPercentage = 80
      }
    })
  ]

  depends_on = [
    helm_release.istio_discovery
  ]
}

resource "helm_release" "istio_egressgateway" {
  name            = "istio-egressgateway"
  repository      = "https://istio-release.storage.googleapis.com/charts"
  chart           = "gateway"
  namespace       = var.istio_namespace
  version         = var.istio_version
  create_namespace = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode({
      replicaCount = 1
      service = {
        type = "ClusterIP"
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      autoscaling = {
        enabled     = true
        minReplicas = 1
        maxReplicas = 3
        targetCPUUtilizationPercentage = 80
      }
    })
  ]

  depends_on = [
    helm_release.istio_discovery
  ]
}
