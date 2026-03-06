# Extensión y Personalización

## Cómo Extender la Configuración

### 1. Agregar un Nuevo Namespace

Editar `terraform/variables.tf`:

```hcl
variable "namespaces" {
  description = "Lista de namespaces a crear"
  type        = list(string)
  default     = [
    "istio-system",
    "istio-dev",
    "istio-prod",
    "istio-staging"  # Agregar aquí
  ]
}
```

Luego ejecutar:
```bash
cd terraform
terraform plan
terraform apply
```

### 2. Modificar Versión de Istio

Editar `terraform/terraform.tfvars`:

```hcl
istio_version = "1.19.0"  # Cambiar versión aquí
```

### 3. Cambiar Recursos de CPU/Memoria

Editar los recursos en `terraform/istio.tf` y `terraform/kiali.tf`:

```hcl
resources = {
  requests = {
    cpu    = "200m"    # Incrementar CPU
    memory = "1024Mi"  # Incrementar memoria
  }
  limits = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
}
```

### 4. Habilitar Componentes Adicionales

En `terraform/terraform.tfvars`:

```hcl
prometheus_enabled = true
grafana_enabled = true
tracing_jaeger_enabled = true
```

### 5. Personalizar Kustomize

Crear un nuevo overlay en `kustomize/overlays/custom/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: istio-custom

namePrefix: custom-

resources:
  - ../../base

patchesStrategicMerge:
  - istiod-patch.yaml
  - kiali-patch.yaml

replicas:
  - name: kiali
    count: 3
```

## Integraciones Comunes

### 1. Integrar con Datadog

Agregar a `terraform/kiali.tf`:

```hcl
variable "datadog_enabled" {
  default = false
}

variable "datadog_api_key" {
  sensitive = true
  default   = ""
}
```

### 2. Integrar con New Relic

Crear un archivo `terraform/newrelic.tf`:

```hcl
resource "helm_release" "newrelic_infra" {
  name  = "newrelic-infrastructure"
  chart = "nri-bundle"
  # ...configuración...
}
```

### 3. Integrar con ELK Stack

Crear un archivo `terraform/elasticsearch.tf`:

```hcl
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://Helm.elastic.co"
  chart      = "elasticsearch"
  # ...configuración...
}
```

### 4. Integrar con Fluentd/Fluent Bit

Crear un archivo `terraform/fluentd.tf`:

```hcl
resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  # ...configuración...
}
```

## Ejemplos de Extensión

### 1. Agregar Argo CD para GitOps

```hcl
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  
  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
}
```

### 2. Agregar Vault para Secretos

```hcl
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  
  values = [
    yamlencode({
      server = {
        dataStorage = {
          size = "10Gi"
        }
      }
    })
  ]
}
```

### 3. Agregar Cert-Manager

```hcl
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  
  set {
    name  = "installCRDs"
    value = "true"
  }
}
```

### 4. Agregar Nginx Ingress Controller

```hcl
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  
  values = [
    yamlencode({
      controller = {
        metrics = {
          enabled = true
        }
      }
    })
  ]
}
```

## Mejores Prácticas

### 1. Usar Variables Sensibles

```hcl
variable "docker_registry_password" {
  sensitive = true
  type      = string
}
```

### 2. Usar Remote State

En `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "istio/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 3. Usar Workspaces para Múltiples Ambientes

```bash
terraform workspace new prod
terraform workspace select prod
terraform apply
```

### 4. Validación de Políticas con Sentinel

Crear `terraform/sentinel.hcl`:

```hcl
policy "require_tags" {
  enforcement_level = "mandatory"
}
```

### 5. Testing con Terraform Test

Crear `terraform/tests/main.tftest.hcl`:

```hcl
run "istio_namespaces_created" {
  command = plan
  
  assert {
    condition = length(kubernetes_namespace.istio_namespaces) == 3
    error_message = "No se crearon los 3 namespaces esperados"
  }
}
```

## Structures de Carpetas Avanzadas

```
project/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   └── terraform.tfvars
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/
│   │   ├── istio/
│   │   ├── kiali/
│   │   └── observability/
│   └── shared/
│       ├── variables.tf
│       └── outputs.tf
├── kustomize/
│   ├── base/
│   └── overlays/
├── policies/
│   ├── security-policies.yaml
│   └── traffic-policies.yaml
└── scripts/
    ├── deploy.sh
    └── backup.sh
```

## Comandos Útiles para Desarrollo

```bash
# Validar sintaxis
terraform validate

# Formatear código
terraform fmt -recursive

# Ver diferencias
terraform plan -out=tfplan
terraform show tfplan

# Destruir recursos específicos
terraform destroy -target=kubernetes_namespace.istio_namespaces[\"istio-dev\"]

# Importar recursos existentes
terraform import kubernetes_namespace.existing-ns existing-ns
```

## Monitoreo en Producción

### 1. Habilitar Logs Centralizados

```bash
kubectl logs -f deployment/istiod -n istio-system | tee istiod.log
```

### 2. Crear Alertas en Prometheus

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: istio-alerts
spec:
  groups:
  - name: istio.rules
    rules:
    - alert: IstioHighErrorRate
      expr: rate(istio_request_total{response_code=~"5.."}[5m]) > 0.05
```

### 3. Crear Dashboards Personalizados en Grafana

- Importar dashboards de Grafana: https://grafana.com/grafana/dashboards/
- Crear dashboards personalizados basados en métricas de Istio

## Recursos Adicionales

- [Istio Official Documentation](https://istio.io/latest/docs/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Kustomize Documentation](https://kustomize.io/)
- [Helm Charts](https://artifacthub.io/)
