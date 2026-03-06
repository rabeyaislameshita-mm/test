#!/bin/bash

# Script para verificar la instalación de Istio y componentes

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Verificación de Instalación de Istio ===${NC}\n"

# 1. Verificar namespaces
echo -e "${YELLOW}1. Verificando namespaces...${NC}"
if kubectl get namespace istio-system &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace istio-system existe"
else
    echo -e "${RED}✗${NC} Namespace istio-system NO existe"
fi

if kubectl get namespace istio-dev &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace istio-dev existe"
else
    echo -e "${RED}✗${NC} Namespace istio-dev NO existe"
fi

if kubectl get namespace istio-prod &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace istio-prod existe"
else
    echo -e "${RED}✗${NC} Namespace istio-prod NO existe"
fi

echo ""

# 2. Verificar Istio components
echo -e "${YELLOW}2. Verificando componentes de Istio...${NC}"

# istiod
if kubectl get deployment istiod -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment istiod -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Istiod está LISTO ($READY réplicas)"
    else
        echo -e "${RED}✗${NC} Istiod NO está listo"
    fi
else
    echo -e "${RED}✗${NC} Istiod NO encontrado"
fi

# Ingress Gateway
if kubectl get deployment istio-ingressgateway -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment istio-ingressgateway -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Istio Ingress Gateway está LISTO ($READY réplicas)"
    else
        echo -e "${RED}✗${NC} Istio Ingress Gateway NO está listo"
    fi
else
    echo -e "${RED}✗${NC} Istio Ingress Gateway NO encontrado"
fi

# Egress Gateway
if kubectl get deployment istio-egressgateway -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment istio-egressgateway -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Istio Egress Gateway está LISTO ($READY réplicas)"
    else
        echo -e "${RED}✗${NC} Istio Egress Gateway NO está listo"
    fi
else
    echo -e "${RED}✗${NC} Istio Egress Gateway NO encontrado"
fi

echo ""

# 3. Verificar Kiali
echo -e "${YELLOW}3. Verificando Kiali...${NC}"

if kubectl get deployment kiali -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment kiali -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Kiali está LISTO ($READY réplicas)"
    else
        echo -e "${RED}✗${NC} Kiali NO está listo"
    fi
else
    echo -e "${RED}✗${NC} Kiali NO encontrado"
fi

echo ""

# 4. Verificar Prometheus
echo -e "${YELLOW}4. Verificando Prometheus...${NC}"

if kubectl get deployment prometheus -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment prometheus -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Prometheus está LISTO"
    else
        echo -e "${RED}✗${NC} Prometheus NO está listo"
    fi
else
    echo -e "${YELLOW}!${NC} Prometheus no encontrado (puede estar usando StatefulSet)"
    if kubectl get statefulset prometheus -n istio-system &> /dev/null; then
        echo -e "${GREEN}✓${NC} Prometheus StatefulSet existe"
    fi
fi

echo ""

# 5. Verificar Grafana
echo -e "${YELLOW}5. Verificando Grafana...${NC}"

if kubectl get deployment prometheus-grafana -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment prometheus-grafana -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Grafana está LISTO"
    else
        echo -e "${RED}✗${NC} Grafana NO está listo"
    fi
else
    echo -e "${YELLOW}!${NC} Grafana no encontrado"
fi

echo ""

# 6. Verificar Jaeger
echo -e "${YELLOW}6. Verificando Jaeger...${NC}"

if kubectl get deployment jaeger -n istio-system &> /dev/null; then
    READY=$(kubectl get deployment jaeger -n istio-system -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Jaeger está LISTO"
    else
        echo -e "${RED}✗${NC} Jaeger NO está listo"
    fi
else
    echo -e "${YELLOW}!${NC} Jaeger no encontrado"
fi

echo ""
echo -e "${YELLOW}7. Resumen de Pods${NC}"
kubectl get pods -n istio-system -o wide

echo ""
echo -e "${YELLOW}=== Verificación Completada ===${NC}"
