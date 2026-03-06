# Comandos Útiles para Trabajar con Istio

## Visualización y Monitoreo

### Acceso a Kiali
```bash
kubectl port-forward -n istio-system svc/kiali-server 20001:20001
# URL: http://localhost:20001
```

### Acceso a Prometheus
```bash
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# URL: http://localhost:9090
```

### Acceso a Grafana
```bash
kubectl port-forward -n istio-system svc/prometheus-grafana 3000:3000
# URL: http://localhost:3000 (usuario: admin, contraseña: admin123)
```

### Acceso a Jaeger
```bash
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686
# URL: http://localhost:16686
```

## Verificación de la Instalación

### Ver versión de Istio
```bash
kubectl get pods -n istio-system -o yaml | grep "image:" | grep -i istio | head -1
istioctl version
```

### Ver configuración de proxy de Envoy
```bash
kubectl get pods -n istio-dev
kubectl exec -it <pod-name> -n istio-dev -c istio-proxy -- envoy-cli stats
```

### Ver configuración de VirtualService
```bash
kubectl get vs -n istio-dev
kubectl describe vs <vs-name> -n istio-dev
```

### Ver configuración de DestinationRule
```bash
kubectl get dr -n istio-dev
kubectl describe dr <dr-name> -n istio-dev
```

## Debugging de Tráfico

### Ver logs de istiod
```bash
kubectl logs -f deployment/istiod -n istio-system
```

### Ver logs del proxy de Envoy
```bash
kubectl logs <pod-name> -c istio-proxy -n istio-dev
```

### Ver configuración del proxy
```bash
kubectl port-forward <pod-name> 15000:15000 -n istio-dev
curl -s localhost:15000/config_dump | jq . | less
```

### Ver cluster configuration
```bash
kubectl port-forward <pod-name> 15000:15000 -n istio-dev
curl -s localhost:15000/clusters | less
```

### Ver routes
```bash
kubectl port-forward <pod-name> 15000:15000 -n istio-dev
curl -s localhost:15000/routes | jq . | less
```

## Aplicación de Políticas

### Habilitar inyección de sidecar en un namespace
```bash
kubectl label namespace <namespace> istio-injection=enabled
```

### Deshabilitar inyección de sidecar en un pod específico
```bash
kubectl annotate pod <pod-name> sidecar.istio.io/inject=false
```

### Aplicar una política de autentificación mutua (mTLS)
```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
```

### Aplicar una política de autorización
```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-all
spec:
  rules:
  - {}
EOF
```

## Pruebas de Conectividad

### Probar conexión entre pods
```bash
# Desde un pod en istio-dev a otro servicio
kubectl exec -it <pod-name> -n istio-dev -- curl http://my-app:8080

# Con verbose
kubectl exec -it <pod-name> -n istio-dev -- curl -v http://my-app:8080
```

### Probar con wget
```bash
kubectl exec -it <pod-name> -n istio-dev -- wget -O- http://my-app:8080
```

### Ver cómo se resuelven los DNS
```bash
kubectl exec -it <pod-name> -n istio-dev -- nslookup my-app
```

## Actualización de Versión

### Actualizar Istio
```bash
cd terraform
terraform plan -var="istio_version=1.19.0"
terraform apply -var="istio_version=1.19.0"
```

## Limpiar Recursos

### Eliminar todos los recursos de Istio
```bash
terraform destroy
```

### Eliminar un namespace específico
```bash
kubectl delete namespace istio-dev
```

### Eliminar una política específica
```bash
kubectl delete peerauthentication/default -n istio-system
kubectl delete authorizationpolicy/allow-all -n istio-system
```

## Observabilidad Avanzada

### Ver trazas distribuidas en Jaeger
```bash
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686
# Acceder a http://localhost:16686
```

### Ver métricas en Prometheus
```bash
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# Acceder a http://localhost:9090 y buscar métricas como:
# - envoy_cluster_upstream_rq
# - envoy_cluster_upstream_rq_time
# - envoy_http_inbound_0_0_0_0_8080_http_downstream_rq
```

### Ver dashboards en Grafana
```bash
kubectl port-forward -n istio-system svc/prometheus-grafana 3000:3000
# Acceder a http://localhost:3000
# Dashboards disponibles:
# - Istio Mesh Dashboard
# - Istio Service Dashboard
# - Istio Workload Dashboard
```

## Seguridad

### Ver certificados de mTLS
```bash
kubectl get secret -n istio-system | grep cert
```

### Verificar que mTLS está habilitado
```bash
kubectl get peerAuthentication -n istio-system
```

### Crear un certificado autofirmado
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
kubectl create secret tls my-app-cert --cert=cert.pem --key=key.pem -n istio-system
```

## Estadísticas y Análisis

### Ver tráfico en tiempo real con Kiali
```bash
kubectl port-forward -n istio-system svc/kiali-server 20001:20001
# En Kiali: Graph > Select namespace > Ver tráfico en vivo
```

### Ver distribución de tráfico
```bash
kubectl port-forward -n istio-system svc/kiali-server 20001:20001
# En Kiali: Services > Seleccionar servicio > Traffic > Ver tráfico por versión
```
