resource "helm_release" "kiali" {
  count            = var.enable_kiali ? 1 : 0
  name             = "kiali-server"
  repository       = "https://kiali.org/helm-charts"
  chart            = "kiali-server"
  namespace        = var.kiali_namespace
  version          = "1.71.0"
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      auth = {
        strategy = "anonymous"
      }
      external_services = {
        prometheus = {
          url = "http://prometheus:9090"
        }
        tracing = {
          enabled         = var.tracing_jaeger_enabled
          namespaceSelector = true
          url             = "http://jaeger:16686"
        }
        grafana = {
          enabled = var.grafana_enabled
          url     = "http://grafana:3000"
        }
        custom_dashboards = {
          enabled = true
        }
      }
      deployment = {
        replicaCount = 2
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      service = {
        type = "ClusterIP"
        port = 20001
      }
      ingress = var.kiali_ingress_enabled ? {
        enabled   = true
        className = "nginx"
        hosts = [
          {
            name = var.kiali_ingress_host
            tls = {
              enabled = true
              secretName = "kiali-tls"
            }
          }
        ]
      } : {}
      tag = var.istio_version
    })
  ]

  depends_on = [
    helm_release.istio_discovery
  ]
}

resource "helm_release" "prometheus" {
  count      = var.prometheus_enabled ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = var.istio_namespace
  version    = "55.7.0"
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention           = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1000Mi"
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues    = false
        }
      }
      grafana = {
        enabled = var.grafana_enabled
        adminPassword = "admin123"
        persistence = {
          enabled = true
          size    = "10Gi"
        }
      }
    })
  ]

  depends_on = [
    helm_release.istio_discovery
  ]
}

resource "helm_release" "jaeger" {
  count      = var.tracing_jaeger_enabled ? 1 : 0
  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = var.istio_namespace
  version    = "0.71.1"
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      provisionDataStore = {
        cassandra = false
        elasticsearch = true
      }
      elasticsearch = {
        enabled = true
        replicas = 1
        config = {
          "xpack.security.enabled" = false
        }
      }
      collector = {
        replicaCount = 1
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
        service = {
          type = "ClusterIP"
        }
      }
      query = {
        replicaCount = 1
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
      }
    })
  ]

  depends_on = [
    helm_release.istio_discovery
  ]
}
