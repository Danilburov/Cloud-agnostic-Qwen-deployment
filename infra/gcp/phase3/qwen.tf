resource "kubernetes_namespace" "llm" {
  metadata {
    name = "llm"
  }
}

resource "time_sleep" "wait_for_namespace" {
  create_duration = "15s"

  depends_on = [
    kubernetes_namespace.llm
  ]
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = var.kserve_gsa_name

  role = "roles/iam.workloadIdentityUser"

  member = "serviceAccount:${var.project_id}.svc.id.goog[llm/kserve-sa]"
}

resource "kubernetes_service_account" "kserve_ksa" {
  metadata {
    name      = "kserve-sa"
    namespace = kubernetes_namespace.llm.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = var.kserve_gsa_email
    }
  }
}

resource "kubernetes_manifest" "qwen_llm" {
  depends_on = [
    kubernetes_namespace.llm
  ]

  manifest = {
    apiVersion = "serving.kserve.io/v1beta1"
    kind       = "InferenceService"

    metadata = {
      name      = "qwen-small"
      #name      = "tiny-llama"
      namespace = "llm"

      annotations = {
        "serving.kserve.io/deploymentMode" = "RawDeployment"
      }
    }

    spec = {
      predictor = {
        serviceAccountName = "kserve-sa"
        model = {
          modelFormat = {
            name = "huggingface"
          }

          storageUri = "gs://${var.project_id}-models/qwen2.5-0.5b"
          #storageUri = "gs://${var.project_id}-models/tinyllama"

          env = [
            {
              name  = "VLLM_CPU_KVCACHE_SPACE"
              value = "1"
            }
          ]

          resources = {
            requests = {
              cpu    = "1"
              memory = "3584Mi"
            }

            limits = {
              cpu    = "2"
              memory = "6Gi"
            }
          }
        }
      }
    }
  }
}


