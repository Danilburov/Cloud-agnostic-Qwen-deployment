resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  create_namespace = true

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "istiod" {
  name      = "istiod"
  namespace = "istio-system"

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name      = "istio-ingress"
  namespace = "istio-system"

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"

  depends_on = [helm_release.istiod]
}