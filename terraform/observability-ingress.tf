# Expone las herramientas de observability via Istio IngressGateway
# Acceso tras el apply:
#   Kiali:      http://kiali.local
#   Grafana:    http://grafana.local
#   Prometheus: http://prometheus.local
#   Jaeger:     http://jaeger.local
#
# En el browser, agrega estas líneas a tu archivo hosts:
#   127.0.0.1  kiali.local grafana.local prometheus.local jaeger.local

# Nota: usa null_resource + local-exec en vez de kubernetes_manifest para que
# Terraform no necesite los CRDs de Istio en tiempo de plan (los CRDs se crean
# durante el apply de los helm_release de Istio).
resource "null_resource" "observability_ingress" {
  triggers = {
    namespace = var.observability_namespace
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-BASH
      kubectl apply -f - <<'ENDOFMANIFEST'
      apiVersion: networking.istio.io/v1beta1
      kind: Gateway
      metadata:
        name: observability-gateway
        namespace: ${var.observability_namespace}
      spec:
        selector:
          istio: ingressgateway
        servers:
        - port:
            number: 80
            name: http
            protocol: HTTP
          hosts:
          - kiali.local
          - grafana.local
          - prometheus.local
          - jaeger.local
      ---
      apiVersion: networking.istio.io/v1beta1
      kind: VirtualService
      metadata:
        name: kiali
        namespace: ${var.observability_namespace}
      spec:
        hosts:
        - kiali.local
        gateways:
        - observability-gateway
        http:
        - match:
          - uri:
              prefix: /
          route:
          - destination:
              host: kiali.${var.observability_namespace}.svc.cluster.local
              port:
                number: 20001
      ---
      apiVersion: networking.istio.io/v1beta1
      kind: VirtualService
      metadata:
        name: grafana
        namespace: ${var.observability_namespace}
      spec:
        hosts:
        - grafana.local
        gateways:
        - observability-gateway
        http:
        - match:
          - uri:
              prefix: /
          route:
          - destination:
              host: prometheus-grafana.${var.observability_namespace}.svc.cluster.local
              port:
                number: 80
      ---
      apiVersion: networking.istio.io/v1beta1
      kind: VirtualService
      metadata:
        name: prometheus
        namespace: ${var.observability_namespace}
      spec:
        hosts:
        - prometheus.local
        gateways:
        - observability-gateway
        http:
        - match:
          - uri:
              prefix: /
          route:
          - destination:
              host: prometheus-kube-prometheus-prometheus.${var.observability_namespace}.svc.cluster.local
              port:
                number: 9090
      ---
      apiVersion: networking.istio.io/v1beta1
      kind: VirtualService
      metadata:
        name: jaeger
        namespace: ${var.observability_namespace}
      spec:
        hosts:
        - jaeger.local
        gateways:
        - observability-gateway
        http:
        - match:
          - uri:
              prefix: /
          route:
          - destination:
              host: jaeger.${var.observability_namespace}.svc.cluster.local
              port:
                number: 16686
      ENDOFMANIFEST
    BASH
  }

  depends_on = [
    helm_release.istio_ingressgateway,
    helm_release.kiali,
    helm_release.prometheus,
    helm_release.jaeger,
  ]
}
