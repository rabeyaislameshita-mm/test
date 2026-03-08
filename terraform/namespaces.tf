resource "kubernetes_namespace" "istio_namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
    labels = {
      name                                           = each.value
      "istio-injection"                              = each.value == "observability" ? "disabled" : "enabled"
      "app.kubernetes.io/managed-by"                = "terraform"
      "app.kubernetes.io/part-of"                   = "istio"
    }
  }

  depends_on = []
}
