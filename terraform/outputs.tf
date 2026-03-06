output "namespaces_created" {
  description = "Namespaces creados"
  value       = var.namespaces
}

output "istio_namespace" {
  description = "Namespace de Istio"
  value       = var.istio_namespace
}

output "istio_ingressgateway_service" {
  description = "Información del servicio Ingress Gateway de Istio"
  value = {
    name      = helm_release.istio_ingressgateway.name
    namespace = var.istio_namespace
    chart     = helm_release.istio_ingressgateway.chart
  }
}

output "istio_version_deployed" {
  description = "Versión de Istio desplegada"
  value       = var.istio_version
}

output "kiali_enabled" {
  description = "¿Kiali está habilitado?"
  value       = var.enable_kiali
}

output "kiali_namespace" {
  description = "Namespace de Kiali"
  value       = var.enable_kiali ? var.kiali_namespace : "N/A"
}

output "kiali_service_url" {
  description = "URL del servicio Kiali dentro del cluster"
  value       = var.enable_kiali ? "http://kiali-server.${var.kiali_namespace}.svc.cluster.local:20001" : "N/A"
}

output "prometheus_enabled" {
  description = "¿Prometheus está habilitado?"
  value       = var.prometheus_enabled
}

output "jaeger_enabled" {
  description = "¿Jaeger está habilitado?"
  value       = var.tracing_jaeger_enabled
}

output "grafana_enabled" {
  description = "¿Grafana está habilitado?"
  value       = var.grafana_enabled
}

output "deployment_info" {
  description = "Información general del despliegue"
  value = {
    istio_namespace      = var.istio_namespace
    app_namespaces       = [for ns in var.namespaces : ns if ns != var.istio_namespace]
    observability_stack  = ["kiali", "prometheus", "grafana", "jaeger"]
    istio_version        = var.istio_version
    managed_by           = "terraform"
    environment          = var.environment
  }
}
