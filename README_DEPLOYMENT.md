# Despliegue de Istio con Terraform y Kustomize

Esta es una solución completa para desplegar Istio en Kubernetes con Terraform y Kustomize, incluyendo Kiali para observabilidad.

## Estructura del Proyecto

```
.
├── terraform/                          # Configuración de Terraform
│   ├── main.tf                        # Archivo principal
│   ├── provider.tf                    # Configuración de providers
│   ├── variables.tf                   # Variables de entrada
│   ├── outputs.tf                     # Outputs
│   ├── namespaces.tf                  # Creación de namespaces
│   ├── istio.tf                       # Instalación de Istio
│   ├── kiali.tf                       # Instalación de Kiali y observabilidad
│   └── terraform.tfvars.example       # Ejemplo de archivo de variables
└── kustomize/                         # Configuración de Kustomize
    ├── kustomization.yaml             # Archivo principal de Kustomize
    ├── base/                          # Recursos base
    │   ├── istio-base.yaml
    │   ├── istiod.yaml
    │   ├── istio-ingressgateway.yaml
    │   ├── istio-egressgateway.yaml
    │   └── kiali.yaml
    └── patches/                       # Parches para Kustomize
        ├── istiod-patch.yaml
        ├── ingressgateway-patch.yaml
        └── kiali-patch.yaml
```

## Requisitos

- Terraform >= 1.0
- Helm CLI >= 3.0
- Kubectl >= 1.24
- Un cluster de Kubernetes activo y accesible
- Archivo kubeconfig configurado

## Instalación Rápida

### 1. Preparar el archivo de variables

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars` con valores personalizados:
- `kubeconfig_path`: Ruta a tu kubeconfig
- `namespaces`: Lista de namespaces a crear
- `istio_version`: Versión de Istio a instalar
- `enable_kiali`: Habilitar Kiali (true/false)

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Revisar el plan de cambios

```bash
terraform plan
```

### 4. Aplicar la configuración

```bash
terraform apply
```

## Namespaces Creados

Por defecto, se crean 3 namespaces:
- `istio-system`: Namespace del sistema de Istio
- `istio-dev`: Namespace para desarrollo
- `istio-prod`: Namespace para producción

Cada namespace (excepto istio-system) tiene la etiqueta `istio-injection=enabled`, lo que significa que Istio inyectará automáticamente sidecars de Envoy en los pods.

## Componentes Instalados

### Istio
- **Istio Base**: CRDs y recursos base
- **Istiod**: Control plane de Istio
- **Ingress Gateway**: Puerta de entrada al cluster
- **Egress Gateway**: Puerta de salida del cluster

### Observabilidad
- **Kiali**: Visualización de la malla de servicios
- **Prometheus**: Recopilación de métricas
- **Grafana**: Visualización de métricas
- **Jaeger**: Trazado distribuido

## Acceso a los Servicios

### Kiali

Para acceder a Kiali desde tu máquina local:

```bash
kubectl port-forward -n istio-system svc/kiali-server 20001:20001
```

Luego accede a: `http://localhost:20001`

### Prometheus

```bash
kubectl port-forward -n istio-system svc/prometheus 9090:9090
```

Accede a: `http://localhost:9090`

### Grafana

```bash
kubectl port-forward -n istio-system svc/prometheus-grafana 3000:3000
```

Accede a: `http://localhost:3000` (Usuario: admin, Contraseña: admin123)

### Jaeger

```bash
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686
```

Accede a: `http://localhost:16686`

## Desinstalación

Para destruir todos los recursos creados:

```bash
cd terraform/
terraform destroy
```

Se te pedirá confirmación antes de eliminar los recursos.

## Personalización con Kustomize

La carpeta `kustomize/` contiene archivos que puedes personalizar:

- `base/`: Recursos base de Istio y Kiali
- `patches/`: Parches para modificar los recursos

Para usar Kustomize:

```bash
kubectl apply -k kustomize/
```

## Variables de Terraform Disponibles

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `kubeconfig_path` | Ruta al kubeconfig | `~/.kube/config` |
| `namespaces` | Namespaces a crear | `["istio-system", "istio-dev", "istio-prod"]` |
| `istio_version` | Versión de Istio | `1.18.2` |
| `enable_kiali` | Habilitar Kiali | `true` |
| `tracing_jaeger_enabled` | Habilitar Jaeger | `true` |
| `prometheus_enabled` | Habilitar Prometheus | `true` |
| `grafana_enabled` | Habilitar Grafana | `true` |
| `environment` | Ambiente | `dev` |

## Troubleshooting

### Los pods no se están iniciando

Verifica el estado de los pods en el namespace istio-system:

```bash
kubectl get pods -n istio-system
```

Para ver los logs:

```bash
kubectl logs -n istio-system deployment/istiod
```

### Kiali no se conecta a Prometheus

Verifica que Prometheus esté ejecutándose:

```bash
kubectl get pods -n istio-system | grep prometheus
```

### La inyección de sidecars no funciona

Verifica que el namespace tenga la etiqueta `istio-injection=enabled`:

```bash
kubectl get namespace --show-labels
```

## Mejores Prácticas

- Usar namespaces separados para diferentes ambientes
- Monitorear regularmente con Kiali y Grafana
- Configurar políticas de tráfico en Istio
- Usar ServiceEntry para servicios externos
- Implementar VirtualServices y DestinationRules para control de tráfico
- Usar PeerAuthentication para mTLS

## Referencias

- [Istio Documentation](https://istio.io/latest/docs/)
- [Kiali Documentation](https://kiali.io/docs/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Kustomize](https://kustomize.io/)
