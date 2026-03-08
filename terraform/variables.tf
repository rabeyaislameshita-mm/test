variable "kubeconfig_path" {
  description = "Ruta al archivo kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "namespaces" {
  description = "Lista de namespaces a crear"
  type        = list(string)
  default     = ["istio-system", "istio-dev", "istio-uat", "observability"]
}

variable "istio_version" {
  description = "Versión de Istio a instalar"
  type        = string
  default     = "1.29.0"
}

variable "istio_namespace" {
  description = "Namespace donde se instalará Istio"
  type        = string
  default     = "istio-system"
}

variable "enable_kiali" {
  description = "Habilitar Kiali"
  type        = bool
  default     = true
}

variable "kiali_namespace" {
  description = "Namespace donde se instalará Kiali"
  type        = string
  default     = "observability"
}

variable "observability_namespace" {
  description = "Namespace donde se instalarán las herramientas de monitoreo (Prometheus, Grafana, Jaeger)"
  type        = string
  default     = "observability"
}

variable "kiali_ingress_enabled" {
  description = "Habilitar Ingress para Kiali"
  type        = bool
  default     = false
}

variable "kiali_ingress_host" {
  description = "Host para el Ingress de Kiali"
  type        = string
  default     = "kiali.example.com"
}

variable "tracing_jaeger_enabled" {
  description = "Habilitar Jaeger para trazado distribuido"
  type        = bool
  default     = true
}

variable "prometheus_enabled" {
  description = "Habilitar Prometheus"
  type        = bool
  default     = true
}

variable "grafana_enabled" {
  description = "Habilitar Grafana"
  type        = bool
  default     = true
}

variable "splunk_enabled" {
  description = "Habilitar Splunk OpenTelemetry Collector"
  type        = bool
  default     = false
}

variable "splunk_access_token" {
  description = "Access token de Splunk Observability Cloud (requerido si splunk_enabled=true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "splunk_realm" {
  description = "Realm de Splunk Observability Cloud (ej: us0, us1, eu0)"
  type        = string
  default     = "us0"
}

variable "splunk_platform_endpoint" {
  description = "URL del HEC endpoint de Splunk Enterprise/Cloud (alternativa a Observability Cloud)"
  type        = string
  default     = ""
}

variable "splunk_platform_token" {
  description = "Token HEC de Splunk Enterprise/Cloud"
  type        = string
  default     = ""
  sensitive   = true
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "istio-deployment"
  }
}
