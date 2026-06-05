resource "kubernetes_config_map_v1_data" "kserve_config" {
  metadata {
    name      = "inferenceservice-config"
    namespace = "kserve"
  }

  data = {
    deploy = jsonencode({
      defaultDeploymentMode = "RawDeployment"
    })
  }

  force = true

  depends_on = [
    helm_release.kserve
  ]
}