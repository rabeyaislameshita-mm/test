# Arquitectura de Deployment

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                     KUBERNETES CLUSTER                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              ISTIO-SYSTEM NAMESPACE                      │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                           │  │
│  │  ┌──────────────┐    ┌──────────────┐   ┌────────────┐  │  │
│  │  │   istiod     │    │   Kiali      │   │ Prometheus │  │  │
│  │  │              │    │              │   │            │  │  │
│  │  │  Control     │    │Observability │   │  Metrics   │  │  │
│  │  │  Plane       │    │    UI        │   │ Collection │  │  │
│  │  └──────────────┘    └──────────────┘   └────────────┘  │  │
│  │                                                           │  │
│  │  ┌──────────────────┐  ┌─────────────┐  ┌────────────┐  │  │
│  │  │  Ingress Gateway │  │ Egress      │  │  Grafana   │  │  │
│  │  │                  │  │ Gateway     │  │            │  │  │
│  │  │  LoadBalancer ── │  │ ClusterIP   │  │ Dashboards │  │  │
│  │  │  External Traffic│  │ Out Traffic │  │            │  │  │
│  │  └──────────────────┘  └─────────────┘  └────────────┘  │  │
│  │                                                           │  │
│  │  ┌─────────────────┐               ┌────────────────┐   │  │
│  │  │     Jaeger      │               │  Elasticsearch │   │  │
│  │  │                 │               │                │   │  │
│  │  │  Distributed    │               │   Storage      │   │  │
│  │  │  Tracing        │               │                │   │  │
│  │  └─────────────────┘               └────────────────┘   │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────┐    ┌──────────────────────┐         │
│  │  ISTIO-DEV NAMESPACE │    │ ISTIO-PROD NAMESPACE │         │
│  ├──────────────────────┤    ├──────────────────────┤         │
│  │ Pods with Envoy      │    │ Pods with Envoy      │         │
│  │ Sidecars Injected    │    │ Sidecars Injected    │         │
│  │                      │    │                      │         │
│  │ - VirtualServices    │    │ - VirtualServices    │         │
│  │ - DestinationRules   │    │ - DestinationRules   │         │
│  │ - ServiceEntries     │    │ - ServiceEntries     │         │
│  │ - PeerAuthtication   │    │ - AuthorizationPolicy│         │
│  └──────────────────────┘    └──────────────────────┘         │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │   OTHER NAMESPACES (istio-injection: enabled)            │  │
│  │   Automatic Envoy proxy sidecar injection                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Flujo de Tráfico

```
External Traffic
       │
       ▼
┌──────────────────┐
│  Ingress Gateway │  (Port 80/443)
│  (LoadBalancer)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Virtual Service │
│  + Routing Rules │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Load Balancing   │
│ + Retries        │
└────────┬─────────┘
         │
         ├─────────────┬──────────────┐
         ▼             ▼              ▼
    ┌────────┐    ┌────────┐    ┌────────┐
    │ Pod v1 │    │ Pod v1 │    │ Pod v2 │
    └────────┘    └────────┘    └────────┘
       │               │            │
       ▼               ▼            ▼
    ┌──────────────────────────────────┐
    │  Envoy Proxy Sidecars            │
    │  - mTLS                          │
    │  - Load Balancing                │
    │  - Telemetry Collection          │
    └────────┬─────────────────────────┘
             │
             ├─────────────────────┬─────────────────────┐
             ▼                     ▼                     ▼
        ┌─────────┐           ┌──────────┐         ┌────────────┐
        │  Kiali  │           │Prometheus│         │  Grafana   │
        │   UI    │           │ Metrics  │         │ Dashboards │
        └─────────┘           └──────────┘         └────────────┘
```

## Namespaces y Servicios

```
Namespace: istio-system
├── istiod (Deployment)
│   └── Expone puerto 15010, 15012, 8888
├── istio-ingressgateway (Deployment)
│   └── Service type: LoadBalancer
│       └── Expone puertos 80, 443
├── istio-egressgateway (Deployment)
│   └── Service type: ClusterIP
│       └── Control de tráfico saliente
├── kiali (Deployment)
│   └── Service: kiali-server
│       └── Observabilidad en puerto 20001
├── prometheus (Deployment/StatefulSet)
│   └── Service: prometheus
│       └── Recopilación de métricas en puerto 9090
├── grafana (Deployment)
│   └── Service: prometheus-grafana
│       └── Visualización en puerto 3000
└── jaeger (Deployment/StatefulSet)
    └── Service: jaeger-query
        └── Trazado distribuido en puerto 16686

Namespace: istio-dev
└── Pods con inyección automática de sidecars
    └── Etiqueta: istio-injection=enabled
    └── Etiqueta: version=v1 o v2

Namespace: istio-prod
└── Pods con inyección automática de sidecars
    └── Etiqueta: istio-injection=enabled
```

## Configuración de Recursos

```
┌──────────────────────────────────────────┐
│  Configuración de Recursos por Pod       │
├──────────────────────────────────────────┤
│                                          │
│  istiod:                                 │
│  ├── Requests: 100m CPU, 512Mi Memory   │
│  └── Limits:   500m CPU, 2048Mi Memory  │
│                                          │
│  Ingress Gateway:                        │
│  ├── Requests: 100m CPU, 128Mi Memory   │
│  ├── Limits:   500m CPU, 512Mi Memory   │
│  ├── Replicas: 2-5 (auto-scaling)       │
│  └── HPA: 80% CPU trigger               │
│                                          │
│  Kiali:                                  │
│  ├── Requests: 100m CPU, 256Mi Memory   │
│  ├── Limits:   500m CPU, 512Mi Memory   │
│  └── Replicas: 2                        │
│                                          │
│  Prometheus:                             │
│  ├── Requests: 100m CPU, 512Mi Memory   │
│  ├── Limits:   500m CPU, 1000Mi Memory  │
│  └── Storage: 50Gi PVC                  │
│                                          │
│  Grafana:                                │
│  ├── Requests: 100m CPU, 128Mi Memory   │
│  └── Storage: 10Gi PVC                  │
│                                          │
│  Jaeger:                                 │
│  ├── Requests: 100m CPU, 128Mi Memory   │
│  └── Collector, Query, Storage           │
│                                          │
└──────────────────────────────────────────┘
```

## Flujo de Deployment con Terraform

```
┌─────────────────────────────────────┐
│  terraform init                     │
│  (Descargar providers)              │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  terraform plan                     │
│  (Mostrar cambios)                  │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  terraform apply                    │
│  (Crear recursos)                   │
└─────────────┬───────────────────────┘
              │
              ├────────────────────┬──────────────────┬─────────────┐
              ▼                    ▼                  ▼             ▼
      ┌──────────────┐    ┌──────────────┐  ┌──────────────┐  ┌──────────┐
    ┌─┤  Namespaces  │    │  Istio Base  │  │  Istiod      │  │ Kiali    │
    │ └──────────────┘    └──────────────┘  └──────────────┘  └──────────┘
    │
    └─ 3 Namespaces
       - istio-system
       - istio-dev
       - istio-prod

      Helm Release Chain:
      1. istio-base
           ▼
      2. istiod
           ├─ istio-ingressgateway
           ├─ istio-egressgateway
           ├─ kiali
           ├─ prometheus
           └─ jaeger
```

## Configuración de Red

```
Control Plane Communication:
┌─────────┐        ┌──────────┐        ┌────────────┐
│  Client │ ─────► │ Istiod   │ ─────► │ Envoy      │
│ (etcd)  │        │ (API)    │        │ (Sidecars) │
└─────────┘        └──────────┘        └────────────┘

Data Plane Traffic:
┌───────────┐   Envoy    ┌──────────────┐   Envoy    ┌───────────┐
│ Pod A v1  │ ─Proxy─────> │ Pod B v1     │ ─Proxy─────> │ External  │
│ (mTLS)    │            │ (mTLS)       │            │ Service   │
└───────────┘            └──────────────┘            └───────────┘

Observability Traffic:
┌──────────────┐    ┌──────────┐    ┌─────────┐    ┌─────────┐
│ Envoy Proxy  │ ── │ Prometheus│ ── │ Grafana │ ── │ Kiali   │
│ (Metrics)    │    │           │    │         │    │         │
└──────────────┘    └──────────┘    └─────────┘    └─────────┘

Tracing Traffic:
┌──────────────┐    ┌────────┐    ┌──────────────┐
│ Envoy Proxy  │ ── │ Jaeger │ ── │ Elasticsearch│
│ (Traces)     │    │        │    │              │
└──────────────┘    └────────┘    └──────────────┘
```

## Flujo de Inyección de Sidecars

```
1. Pod es creado en istio-dev namespace
   │
   ├─ Namespace tiene label: istio-injection=enabled
   │
   ├─ Mutating Webhook (istiod) intercepta la creación
   │
   ├─ Inyecta contenedor istio-proxy
   │
   └─ Pod se crea con:
      - Container: app
      - Container: istio-proxy (Envoy)
      - Volume: istio-token
      - InitContainer: istio-init

2. Resultado:
   Pod con múltiples contenedores:
   ├── app (tu aplicación)
   ├── istio-proxy (Envoy)
   └── InitContainers para configuración de red
```

## Ciclo de Obtención de Métricas

```
1. Envoy Proxy recopila métricas
   │
   ▼
2. Prometheus scrape de endpoints
   │
   ├─ :15000 (Envoy admin)
   ├─ :8883 (Prometheus metrics)
   └─ :9090 (Prometheus server)
   │
   ▼
3. Kiali consulta Prometheus
   │
   ▼
4. Grafana muestra dashboards
   │
   ▼
5. Usuario visualiza en UI
```

## Seguridad (mTLS) Flujo

```
Antes (sin mTLS):
Pod A ─────(HTTP)────────► Pod B

Después (con mTLS):
Pod A ─Envoy─  
       │ 1. Crear certificado
       │ 2. Validar certificado de Pod B
       │ 3. Establecer conexión TLS
       ▼
      TLS ────────────────► Pod B Envoy
                                 │ 3. Descifrar
                                 │ 4. Entregar a app
                                 ▼
                            Aplicación
```
