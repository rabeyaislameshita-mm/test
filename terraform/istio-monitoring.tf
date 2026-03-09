# ServiceMonitor para Istiod (métricas del control plane de Istio)
# Nota: usa null_resource + local-exec para evitar el error de CRDs faltantes en tiempo de plan.
resource "null_resource" "istiod_service_monitor" {
  count = var.prometheus_enabled ? 1 : 0

  triggers = {
    namespace = var.observability_namespace
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-BASH
      kubectl apply -f - <<'ENDOFMANIFEST'
      apiVersion: monitoring.coreos.com/v1
      kind: ServiceMonitor
      metadata:
        name: istiod
        namespace: ${var.observability_namespace}
        labels:
          release: prometheus
      spec:
        namespaceSelector:
          matchNames:
          - istio-system
        selector:
          matchLabels:
            app: istiod
        endpoints:
        - port: http-monitoring
          interval: 15s
      ENDOFMANIFEST
    BASH
  }

  depends_on = [
    helm_release.prometheus
  ]
}

# PodMonitor para sidecars de Envoy (métricas de request/response en la malla)
resource "null_resource" "envoy_stats_pod_monitor" {
  count = var.prometheus_enabled ? 1 : 0

  triggers = {
    namespace = var.observability_namespace
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-BASH
      kubectl apply -f - <<'ENDOFMANIFEST'
      apiVersion: monitoring.coreos.com/v1
      kind: PodMonitor
      metadata:
        name: envoy-stats
        namespace: ${var.observability_namespace}
        labels:
          release: prometheus
      spec:
        namespaceSelector:
          any: true
        selector:
          matchExpressions:
          - key: istio-prometheus-ignore
            operator: DoesNotExist
        podMetricsEndpoints:
        - path: /stats/prometheus
          port: http-envoy-prom
          interval: 15s
          relabelings:
          - action: keep
            sourceLabels: [__meta_kubernetes_pod_container_name]
            regex: istio-proxy
          - action: labeldrop
            regex: __meta_kubernetes_pod_label_skaffold_dev.*
          - sourceLabels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:15090
            targetLabel: __address__
      ENDOFMANIFEST
    BASH
  }

  depends_on = [
    helm_release.prometheus
  ]
}
