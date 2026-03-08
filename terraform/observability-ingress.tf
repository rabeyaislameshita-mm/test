# Expone las herramientas de observability via Istio IngressGateway
# Acceso tras el apply:
#   Kiali:      http://172.19.0.6  (o via: curl -H "Host: kiali.local" http://172.19.0.6)
#   Grafana:    http://172.19.0.6  con Host: grafana.local
#   Prometheus: http://172.19.0.6  con Host: prometheus.local
#   Jaeger:     http://172.19.0.6  con Host: jaeger.local
#
# En el browser, agrega estas líneas a tu archivo hosts:
#   172.19.0.6  kiali.local grafana.local prometheus.local jaeger.local

resource "kubernetes_manifest" "observability_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "observability-gateway"
      namespace = var.observability_namespace
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = [
            "kiali.local",
            "grafana.local",
            "prometheus.local",
            "jaeger.local",
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.kiali,
    helm_release.prometheus,
    helm_release.jaeger,
  ]
}

resource "kubernetes_manifest" "kiali_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "kiali"
      namespace = var.observability_namespace
    }
    spec = {
      hosts    = ["kiali.local"]
      gateways = ["observability-gateway"]
      http = [
        {
          match = [{ uri = { prefix = "/" } }]
          route = [
            {
              destination = {
                host = "kiali.${var.observability_namespace}.svc.cluster.local"
                port = { number = 20001 }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.observability_gateway]
}

resource "kubernetes_manifest" "grafana_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "grafana"
      namespace = var.observability_namespace
    }
    spec = {
      hosts    = ["grafana.local"]
      gateways = ["observability-gateway"]
      http = [
        {
          match = [{ uri = { prefix = "/" } }]
          route = [
            {
              destination = {
                host = "prometheus-grafana.${var.observability_namespace}.svc.cluster.local"
                port = { number = 80 }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.observability_gateway]
}

resource "kubernetes_manifest" "prometheus_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "prometheus"
      namespace = var.observability_namespace
    }
    spec = {
      hosts    = ["prometheus.local"]
      gateways = ["observability-gateway"]
      http = [
        {
          match = [{ uri = { prefix = "/" } }]
          route = [
            {
              destination = {
                host = "prometheus-kube-prometheus-prometheus.${var.observability_namespace}.svc.cluster.local"
                port = { number = 9090 }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.observability_gateway]
}

resource "kubernetes_manifest" "jaeger_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "jaeger"
      namespace = var.observability_namespace
    }
    spec = {
      hosts    = ["jaeger.local"]
      gateways = ["observability-gateway"]
      http = [
        {
          match = [{ uri = { prefix = "/" } }]
          route = [
            {
              destination = {
                host = "jaeger.${var.observability_namespace}.svc.cluster.local"
                port = { number = 16686 }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.observability_gateway]
}
