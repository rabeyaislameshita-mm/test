resource "helm_release" "kiali" {
  count            = var.enable_kiali ? 1 : 0
  name             = "kiali-server"
  repository       = "https://kiali.org/helm-charts"
  chart            = "kiali-server"
  namespace        = var.kiali_namespace
  version          = "2.22.0"
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
          url = "http://prometheus-kube-prometheus-prometheus.observability.svc.cluster.local:9090"
        }
        tracing = {
          enabled      = var.tracing_jaeger_enabled
          provider     = "jaeger"
          internal_url = "http://jaeger.observability.svc.cluster.local:16686"
          external_url = "http://jaeger.local"
          use_grpc     = false
        }
        grafana = {
          enabled      = var.grafana_enabled
          internal_url = "http://prometheus-grafana.observability.svc.cluster.local:80"
          external_url = "http://grafana.local"
          auth = {
            username = "admin"
            password = "admin123"
            type     = "basic"
          }
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
      ingress = {
        enabled   = var.kiali_ingress_enabled
        className = var.kiali_ingress_enabled ? "nginx" : ""
        hosts = var.kiali_ingress_enabled ? [
          {
            name = var.kiali_ingress_host
            tls = {
              enabled    = true
              secretName = "kiali-tls"
            }
          }
        ] : []
      }
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
  namespace  = var.observability_namespace
  version    = "82.10.1"
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
  namespace  = var.observability_namespace
  version    = "4.5.0"
  wait       = true
  timeout    = 600

  # Jaeger v4.x usa arquitectura All-in-One con OpenTelemetry Collector.
  # El almacenamiento embebido (Elasticsearch/Cassandra) fue eliminado.
  # Por defecto usa memoria (efímero). Para producción configure
  # almacenamiento externo via userconfig.extensions.jaeger_storage.
  values = [
    yamlencode({
      jaeger = {
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

resource "helm_release" "splunk_otel_collector" {
  count      = var.splunk_enabled ? 1 : 0
  name       = "splunk-otel-collector"
  repository = "https://signalfx.github.io/splunk-otel-collector-chart"
  chart      = "splunk-otel-collector"
  namespace  = var.observability_namespace
  version    = "0.146.0"
  wait       = true
  timeout    = 300

  values = [
    yamlencode({
      clusterName = "istio-cluster"

      splunkObservability = {
        accessToken = var.splunk_access_token
        realm       = var.splunk_realm
      }

      splunkPlatform = var.splunk_platform_endpoint != "" ? {
        endpoint = var.splunk_platform_endpoint
        token    = var.splunk_platform_token
        index    = "main"
      } : null

      agent = {
        enabled = true
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      clusterReceiver = {
        enabled = true
        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "256Mi"
          }
        }
      }

      logsCollection = {
        enabled    = true
        containers = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [
    helm_release.istio_discovery
  ]
}
