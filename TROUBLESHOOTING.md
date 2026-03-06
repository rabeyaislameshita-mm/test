# Troubleshooting - Solución de Problemas

## Problemas Comunes y Soluciones

### 1. Los pods de Istio no se inician

**Síntoma**: Los pods en istio-system están en estado `Pending` o `CrashLoopBackOff`

**Solución**:
```bash
# Ver eventos del pod
kubectl describe pod <pod-name> -n istio-system

# Ver logs del pod
kubectl logs <pod-name> -n istio-system

# Verificar recursos disponibles
kubectl top nodes
kubectl describe node <node-name>

# Si hay insuficientes recursos, aumentar las resources en terraform
```

### 2. Kiali no puede conectarse a Prometheus

**Síntoma**: En Kiali aparece mensaje de error "No datos disponibles"

**Solución**:
```bash
# Verificar que Prometheus esté corriendo
kubectl get pods -n istio-system | grep prometheus

# Verificar la configuración de Kiali
kubectl get cm -n istio-system kiali-config -o yaml

# Probar conectividad entre pods
kubectl exec -it <kiali-pod> -n istio-system -- curl http://prometheus:9090/api/v1/query?query=up
```

### 3. Los sidecars no se inyectan automáticamente

**Síntoma**: Los pods no tienen el contenedor `istio-proxy`

**Solución**:
```bash
# Verificar que el namespace tiene la etiqueta correcta
kubectl get namespace --show-labels

# Agregar la etiqueta si falta
kubectl label namespace <namespace> istio-injection=enabled

# Recrear los pods
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

### 4. Terraform apply falla con error de conexión

**Síntoma**: Error "Unable to connect to Kubernetes"

**Solución**:
```bash
# Verificar kubeconfig
kubectl config current-context
kubectl cluster-info

# Actualizar la ruta de kubeconfig en terraform.tfvars
# Asegurarse de que la ruta es correcta

# Probar conexión manualmente
kubectl get nodes
```

### 5. Error: "helm: unknown command"

**Síntoma**: Terraform no puede encontrar Helm

**Solución**:
```bash
# Verificar que Helm está instalado
helm version

# Si no está instalado, instalarlo
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar que está en PATH
which helm
```

### 6. Los ingress gateways no tienen IP externa

**Síntoma**: El servicio `istio-ingressgateway` muestra `<pending>` en EXTERNAL-IP

**Solución**:
```bash
# En clusters locales (minikube, docker-desktop), usar port-forward
kubectl port-forward -n istio-system svc/istio-ingressgateway 80:80

# En clusters cloud, esperar o verificar:
kubectl get svc -n istio-system istio-ingressgateway
```

### 7. mTLS está rompiendo la comunicación

**Síntoma**: Los pods no pueden comunicarse entre sí, conexiones rechazadas

**Solución**:
```bash
# Verificar configuración de mTLS
kubectl get peerauthentication

# Desabilitar mTLS temporalmente
kubectl delete peerauthentication -n istio-system default

# Verificar logs de Envoy
kubectl logs <pod-name> -c istio-proxy -n <namespace>
```

### 8. Prometheus no recopila métricas

**Síntoma**: Prometheus dice "No timeseries data found"

**Solución**:
```bash
# Verificar que el scraping está configurado
kubectl get pods -n istio-system | grep prometheus

# Verificar configuración de scraping
kubectl get cm prometheus-config -n istio-system -o yaml

# Esperar a que Prometheus comience a recopilar (puede tomar minutos)
sleep 60
```

### 9. Error con recursos no encontrados

**Síntoma**: `Error: map[]: Kind <kind> is missing in schema`

**Solución**:
```bash
# Puede ser un problema de versión de CRD
# Actualizar los proveedores de Terraform
cd terraform
rm terraform.lock.hcl
terraform init

# O actualizar la versión de Kubernetes provider
```

### 10. Los logs de Terraform muestran advertencias de deprecación

**Síntoma**: Warnings sobre APIs deprecadas

**Solución**:
```bash
# Actualizar la versión de los providers en provider.tf
# Por ejemplo, cambiar version de kubernetes provider

# Ejecutar terraform plan para ver cambios
terraform plan

# Aplicar los cambios
terraform apply
```

## Verificación Rápida

Usa el script `verify-installation.sh` para verificar rápidamente el estado:

```bash
./verify-installation.sh
```

## Comandos de Debugging

### Ver estado de Istio
```bash
istioctl analyze
```

### Ver configuración de proxy
```bash
kubectl port-forward <pod-name> 15000:15000 -n istio-dev
curl -s localhost:15000/config_dump | jq .
```

### Ver estadísticas de Envoy
```bash
kubectl exec -it <pod-name> -c istio-proxy -n istio-dev -- envoy-cli stats
```

### Ver rutas
```bash
kubectl port-forward <pod-name> 15000:15000 -n istio-dev
curl -s localhost:15000/routes | jq .
```

### Ver clusters
```bash
kubectl port-forward <pod-name> 15000:15000 -n istio-dev
curl -s localhost:15000/clusters | jq .
```

## Logs Importantes

### Istiod logs
```bash
kubectl logs -f deployment/istiod -n istio-system
```

### Envoy proxy logs
```bash
kubectl logs <pod-name> -c istio-proxy -n istio-dev
```

### Kiali logs
```bash
kubectl logs -f deployment/kiali -n istio-system
```

### Prometheus logs
```bash
kubectl logs -f <prometheus-pod> -n istio-system
```

## Recursos de Ayuda

- Documentación oficial de Istio: https://istio.io/latest/docs/
- GitHub Issues: https://github.com/istio/istio/issues
- Slack de Istio: https://istio.io/latest/get-involved/

## Contacto

Si los problemas persisten, verifica:
1. La versión de Kubernetes es compatible
2. Tienes permisos suficientes en el cluster
3. Los recursos del cluster son suficientes
4. Las configuraciones de firewall no bloquean puertos necesarios
