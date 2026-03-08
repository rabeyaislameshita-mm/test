.PHONY: help init plan apply destroy verify test clean all unlock

# Variables
TERRAFORM_DIR := terraform
KUSTOMIZE_DIR := kustomize

help: ## Mostrar ayuda
	@echo "Istio Deployment - Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Inicializar Terraform
	@echo "Inicializando Terraform..."
	@cd $(TERRAFORM_DIR) && terraform init

plan: ## Mostrar plan de Terraform
	@echo "Generando plan de Terraform..."
	@cd $(TERRAFORM_DIR) && terraform plan

apply: ## Aplicar configuración de Terraform
	@echo "Aplicando configuración de Terraform..."
	@cd $(TERRAFORM_DIR) && terraform apply

destroy: ## Destruir recursos de Terraform
	@echo "Destruyendo recursos de Terraform..."
	@cd $(TERRAFORM_DIR) && terraform destroy

verify: ## Verificar instalación
	@echo "Verificando instalación de Istio..."
	@bash verify-installation.sh

test: ## Ejecutar pruebas
	@echo "Ejecutando pruebas..."
	@kubectl get pods -n istio-system
	@kubectl get vs -n istio-dev 2>/dev/null || echo "No VirtualServices encontrados"
	@kubectl get dr -n istio-dev 2>/dev/null || echo "No DestinationRules encontrados"

clean: ## Limpiar directorios de Terraform
	@echo "Limpiando directorios..."
	@rm -rf $(TERRAFORM_DIR)/.terraform
	@rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	@rm -f $(TERRAFORM_DIR)/tfplan
	@rm -f $(TERRAFORM_DIR)/terraform.tfstate*

unlock: ## Eliminar el state lock de Terraform si quedó bloqueado
	@echo "Eliminando Terraform state lock..."
	@if [ -f $(TERRAFORM_DIR)/.terraform.tfstate.lock.info ]; then \
		LOCK_ID=$$(cat $(TERRAFORM_DIR)/.terraform.tfstate.lock.info | grep -o '"ID":"[^"]*"' | cut -d'"' -f4); \
		echo "Lock ID: $$LOCK_ID"; \
		cd $(TERRAFORM_DIR) && terraform force-unlock -force $$LOCK_ID 2>/dev/null || true; \
		rm -f .terraform.tfstate.lock.info; \
		echo "Lock eliminado."; \
	else \
		echo "No hay lock activo."; \
	fi

kiali: ## Acceso a Kiali
	@echo "Abriendo Kiali en http://localhost:20001"
	@kubectl port-forward -n observability svc/kiali 20001:20001

prometheus: ## Acceso a Prometheus
	@echo "Abriendo Prometheus en http://localhost:9090"
	@kubectl port-forward -n observability svc/prometheus-kube-prometheus-prometheus 9090:9090

grafana: ## Acceso a Grafana
	@echo "Abriendo Grafana en http://localhost:3000"
	@kubectl port-forward -n observability svc/prometheus-grafana 3000:3000

jaeger: ## Acceso a Jaeger
	@echo "Abriendo Jaeger en http://localhost:16686"
	@kubectl port-forward -n observability svc/jaeger 16686:16686

status: ## Ver estado de Istio
	@echo "Estado de componentes de Istio:"
	@kubectl get pods -n istio-system -o wide
	@echo ""
	@kubectl get svc -n istio-system

logs-istiod: ## Ver logs de istiod
	@kubectl logs -f deployment/istiod -n istio-system

logs-kiali: ## Ver logs de Kiali
	@kubectl logs -f deployment/kiali -n istio-system

logs-prometheus: ## Ver logs de Prometheus
	@kubectl logs -f -l app.kubernetes.io/name=prometheus -n istio-system

logs-splunk: ## Ver logs del Splunk OTel Collector
	@kubectl logs -f -l app=splunk-otel-collector -n observability

deploy-example: ## Desplegar aplicación de ejemplo
	@echo "Desplegando aplicación de ejemplo..."
	@kubectl apply -f examples/sample-app.yaml

delete-example: ## Eliminar aplicación de ejemplo
	@echo "Eliminando aplicación de ejemplo..."
	@kubectl delete -f examples/sample-app.yaml

kustomize-dev: ## Aplicar Kustomize para desarrollo
	@echo "Aplicando Kustomize para desarrollo..."
	@kubectl apply -k $(KUSTOMIZE_DIR)/overlays/dev

kustomize-prod: ## Aplicar Kustomize para producción
	@echo "Aplicando Kustomize para producción..."
	@kubectl apply -k $(KUSTOMIZE_DIR)/overlays/prod

all: init plan apply verify ## Ejecutar inicialización, plan, apply y verificación

version: ## Mostrar versiones de herramientas
	@echo "Versiones de herramientas:"
	@echo "Terraform: $$(terraform version -json | jq -r '.terraform_version')"
	@echo "kubectl: $$(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
	@echo "Helm: $$(helm version --short)"
	@echo "Istio: $$(kubectl get pods -n istio-system -o yaml 2>/dev/null | grep 'image.*pilot' | head -1 | sed 's/.*://' | awk '{print $$1}')"

describe-resources: ## Describir recursos principales
	@echo "Recursos de Istio:"
	@kubectl get all -n istio-system -o wide

.DEFAULT_GOAL := help
