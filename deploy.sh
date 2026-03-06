#!/bin/bash

# Script de despliegue automático de Istio con Terraform

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones auxiliares
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar requisitos
check_requirements() {
    log_info "Verificando requisitos..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform no está instalado"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "Kubectl no está instalado"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_error "Helm no está instalado"
        exit 1
    fi
    
    log_info "✓ Todos los requisitos están cumplidos"
}

# Verificar conexión a Kubernetes
check_kubernetes() {
    log_info "Verificando conexión a Kubernetes..."
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "No se puede conectar al cluster de Kubernetes"
        exit 1
    fi
    
    log_info "✓ Conectado al cluster de Kubernetes"
}

# Inicializar Terraform
init_terraform() {
    log_info "Inicializando Terraform..."
    cd terraform
    terraform init
    cd ..
    log_info "✓ Terraform inicializado"
}

# Mostrar plan de cambios
show_plan() {
    log_info "Generando plan de Terraform..."
    cd terraform
    terraform plan -out=tfplan
    cd ..
}

# Aplicar configuración
apply_terraform() {
    log_info "Aplicando configuración de Terraform..."
    cd terraform
    terraform apply tfplan
    cd ..
    log_info "✓ Configuración aplicada"
}

# Esperar a que los deployments estén listos
wait_for_deployments() {
    log_info "Esperando a que los deployments estén listos..."
    
    kubectl rollout status deployment/istiod -n istio-system --timeout=5m
    kubectl rollout status deployment/istio-ingressgateway -n istio-system --timeout=5m
    kubectl rollout status deployment/kiali -n istio-system --timeout=5m
    
    log_info "✓ Todos los deployments están listos"
}

# Mostrar información de acceso
show_access_info() {
    log_info "Información de acceso a los servicios:"
    echo ""
    echo "Kiali:"
    echo "  kubectl port-forward -n istio-system svc/kiali-server 20001:20001"
    echo "  URL: http://localhost:20001"
    echo ""
    echo "Prometheus:"
    echo "  kubectl port-forward -n istio-system svc/prometheus 9090:9090"
    echo "  URL: http://localhost:9090"
    echo ""
    echo "Grafana:"
    echo "  kubectl port-forward -n istio-system svc/prometheus-grafana 3000:3000"
    echo "  URL: http://localhost:3000 (Usuario: admin, Contraseña: admin123)"
    echo ""
    echo "Jaeger:"
    echo "  kubectl port-forward -n istio-system svc/jaeger-query 16686:16686"
    echo "  URL: http://localhost:16686"
    echo ""
}

# Función principal
main() {
    log_info "Iniciando despliegue de Istio con Terraform..."
    echo ""
    
    check_requirements
    echo ""
    
    check_kubernetes
    echo ""
    
    init_terraform
    echo ""
    
    show_plan
    echo ""
    
    read -p "¿Continuar con la aplicación? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        apply_terraform
        echo ""
        
        wait_for_deployments
        echo ""
        
        show_access_info
        
        log_info "✓ Despliegue completado exitosamente"
    else
        log_warn "Despliegue cancelado"
    fi
}

# Ejecutar función principal
main
