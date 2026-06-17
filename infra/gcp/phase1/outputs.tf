output "project_id" {
  value = google_project.sue_project.project_id
}

output "cluster_name" {
  value = google_container_cluster.gke.name
}

output "region" {
  value = var.region
}

output "cluster_endpoint" {
  value = google_container_cluster.gke.endpoint
}

output "models_bucket" {
  value = google_storage_bucket.models.name
}

output "kserve_gsa_email" {
  value = google_service_account.kserve_gsa.email
}

output "kserve_gsa_name" {
  value = google_service_account.kserve_gsa.name
}