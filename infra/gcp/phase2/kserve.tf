resource "helm_release" "kserve_crds" {
  name             = "kserve-crds"
  namespace        = "kserve"
  create_namespace = true

  repository = "oci://ghcr.io/kserve/charts"
  chart      = "kserve-crd"
  version    = "v0.16.0"

  depends_on = [
    helm_release.istio_ingress
  ]
}

resource "helm_release" "kserve" {
  name      = "kserve"
  namespace = "kserve"

  repository = "oci://ghcr.io/kserve/charts"
  chart      = "kserve"
  version    = "v0.16.0"
  

  depends_on = [
    helm_release.kserve_crds
  ]
}