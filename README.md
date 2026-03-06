# Istio Deployment with Terraform, Helm, and Kustomize

Un proyecto completo para desplegar Istio en Kubernetes con Terraform, Helm y Kustomize, incluyendo Kiali para observabilidad, Prometheus, Grafana y Jaeger para monitoreo y trazado distribuido.

## 🚀 Características

- ✅ **Terraform** para IaC (Infrastructure as Code)
- ✅ **Helm** para la instalación de Istio y componentes
- ✅ **Kustomize** para personalización y gestión de configuraciones
- ✅ **3 Namespaces**: istio-system, istio-dev, istio-prod
- ✅ **Kiali** habilitado para visualización de la malla de servicios
- ✅ **Prometheus** para recopilación de métricas
- ✅ **Grafana** para visualización de métricas
- ✅ **Jaeger** para trazado distribuido
- ✅ **Ingress Gateway** para tráfico externo
- ✅ **Egress Gateway** para tráfico saliente
- ✅ **mTLS** habilitado de forma segura

## 📁 Estructura del Proyecto

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
├── kustomize/                         # Configuración de Kustomize
│   ├── kustomization.yaml
│   ├── base/                          # Recursos base
│   ├── patches/                       # Parches para personalización
│   └── overlays/                      # Overlays para diferentes ambientes
├── examples/                          # Ejemplos de uso
│   ├── istio-examples.yaml            # Ejemplos de VirtualService, etc.
│   └── sample-app.yaml                # Aplicación de ejemplo
├── deploy.sh                          # Script de despliegue automático
├── verify-installation.sh             # Script para verificar la instalación
├── README_DEPLOYMENT.md               # Documentación detallada
├── USEFUL_COMMANDS.md                 # Comandos útiles
└── .gitignore                         # Configuration de Git
```

## 🎯 Requisitos

- **Terraform** >= 1.0
- **Helm CLI** >= 3.0
- **Kubectl** >= 1.24
- **Cluster de Kubernetes** accesible
- **Kubeconfig** configurado

## ⚡ Inicio Rápido

### 1. Clonar o preparar el repositorio
```bash
cd /workspaces/test
```

### 2. Configurar variables de Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars según sea necesario
```

### 3. Desplegar con el script automático
```bash
cd ..
chmod +x deploy.sh
./deploy.sh
```

### O desplegar manualmente
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Verificar la instalación
```bash
./verify-installation.sh
```

## 📊 Acceso a los Servicios

Una vez desplegado, puedes acceder a los servicios:

### Kiali (Visualización de la Malla)
```bash
kubectl port-forward -n istio-system svc/kiali-server 20001:20001
# http://localhost:20001
```

### Prometheus (Métricas)
```bash
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# http://localhost:9090
```

### Grafana (Dashboards)
```bash
kubectl port-forward -n istio-system svc/prometheus-grafana 3000:3000
# http://localhost:3000 (usuario: admin, contraseña: admin123)
```

### Jaeger (Trazas)
```bash
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686
# http://localhost:16686
```

## 📚 Documentación

- [README_DEPLOYMENT.md](README_DEPLOYMENT.md) - Documentación detallada de despliegue
- [USEFUL_COMMANDS.md](USEFUL_COMMANDS.md) - Comandos útiles para trabajar con Istio

## 📝 Ejemplos

Consulta la carpeta `examples/`:
- `istio-examples.yaml` - Ejemplos de VirtualService, DestinationRule, Gateway, etc.
- `sample-app.yaml` - Aplicación de ejemplo para desplegar en Istio

Para aplicar los ejemplos:
```bash
kubectl apply -f examples/sample-app.yaml
```

## 🛠️ Personalización

### Cambiar versión de Istio
```bash
terraform apply -var="istio_version=1.19.0"
```

### Habilitar/Deshabilitar componentes
```bash
terraform apply -var="enable_kiali=true" -var="prometheus_enabled=true"
```

### Usar Kustomize overlays
```bash
# Para desarrollo
kubectl apply -k kustomize/overlays/dev

# Para producción
kubectl apply -k kustomize/overlays/prod
```

## 🧹 Limpieza

Para eliminar todos los recursos:
```bash
cd terraform
terraform destroy
```

## 🔐 Seguridad

- **mTLS** está habilitado en todos los namespaces
- Los pods obtienen inyección automática de sidecars de Envoy
- Se implementan políticas de autorización (AuthorizationPolicy)
- Se utiliza autenticación de pares (PeerAuthentication)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, crea un fork del proyecto y envía pull requests.

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

## 📞 Soporte

Para preguntas o problemas, consulta la documentación o abre un issue.