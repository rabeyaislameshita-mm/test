#!/bin/bash

# Script para validar la sintaxis de archivos de Terraform, Kubernetes y YAML

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo -e "${YELLOW}=== Validación de Sintaxis ===${NC}\n"

# Validar archivos de Terraform
echo -e "${YELLOW}Validando archivos de Terraform...${NC}"

if command -v terraform &> /dev/null; then
    cd terraform
    if terraform fmt -check -recursive . 2>/dev/null; then
        log_info "Archivos de Terraform correctamente formateados"
    else
        log_warn "Algunos archivos de Terraform no están correctamente formateados"
        log_warn "Ejecutar: terraform fmt -recursive terraform/"
    fi
    
    if terraform validate 1>/dev/null 2>&1; then
        log_info "Archivos de Terraform tienen sintaxis válida"
    else
        log_error "Algunos archivos de Terraform tienen errores de sintaxis"
        terraform validate
    fi
    cd ..
else
    log_warn "Terraform no está instalado, skipping Terraform validation"
fi

echo ""

# Validar archivos YAML
echo -e "${YELLOW}Validando archivos YAML...${NC}"

if command -v yamllint &> /dev/null; then
    if yamllint examples/ kustomize/ 2>/dev/null; then
        log_info "Archivos YAML tienen sintaxis válida"
    else
        log_warn "Algunos archivos YAML tienen problemas de sintaxis"
    fi
else
    log_warn "yamllint no está instalado, instalando..."
    pip install yamllint 2>/dev/null || \
    apt-get install -y yamllint 2>/dev/null || \
    log_warn "No se pudo instalar yamllint"
fi

echo ""

# Validar archivos de Kubernetes
echo -e "${YELLOW}Validando archivos de Kubernetes con kubectl...${NC}"

if command -v kubectl &> /dev/null; then
    for file in examples/*.yaml kustomize/base/*.yaml; do
        if [ -f "$file" ]; then
            if kubectl apply --dry-run=client -f "$file" 2>/dev/null; then
                log_info "Validado: $file"
            else
                log_error "Error en: $file"
            fi
        fi
    done
else
    log_warn "kubectl no está instalado"
fi

echo ""

# Validar Kustomize
echo -e "${YELLOW}Validando archivos de Kustomize...${NC}"

if command -v kustomize &> /dev/null; then
    if kustomize build kustomize/ 1>/dev/null 2>&1; then
        log_info "Kustomize base está válido"
    else
        log_error "Error en Kustomize base"
    fi
    
    if kustomize build kustomize/overlays/dev 1>/dev/null 2>&1; then
        log_info "Kustomize overlay dev está válido"
    else
        log_error "Error en Kustomize overlay dev"
    fi
    
    if kustomize build kustomize/overlays/prod 1>/dev/null 2>&1; then
        log_info "Kustomize overlay prod está válido"
    else
        log_error "Error en Kustomize overlay prod"
    fi
else
    log_warn "kustomize no está instalado"
fi

echo ""
echo -e "${YELLOW}=== Validación Completada ===${NC}"
