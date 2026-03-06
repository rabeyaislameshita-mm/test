# Este es el archivo principal de Terraform para desplegar Istio con Kiali

# Los recursos se definen en los otros archivos:
# - provider.tf: Configuración de providers (Terraform, Kubernetes, Helm)
# - variables.tf: Variables de entrada
# - namespaces.tf: Creación de namespaces de Kubernetes
# - istio.tf: Instalación de Istio usando Helm
# - kiali.tf: Instalación de Kiali, Prometheus, Grafana y Jaeger
# - outputs.tf: Outputs de los recursos creados

# Para usar este despliegue:
# 1. Copiar terraform.tfvars.example a terraform.tfvars
# 2. Ajustar los valores según sea necesario
# 3. Ejecutar: terraform init
# 4. Ejecutar: terraform plan para revisar los cambios
# 5. Ejecutar: terraform apply para crear los recursos
