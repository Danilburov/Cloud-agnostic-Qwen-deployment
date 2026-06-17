resource "google_storage_bucket" "models" {
  name                        = "${var.project_id}-models"
  project                     = var.project_id
  location                    = "US"
  uniform_bucket_level_access = true

  force_destroy = true

  depends_on = [
    google_project.sue_project,
    time_sleep.wait_for_apis
  ]
}

#
# Google Service Account used by KServe
#
resource "google_service_account" "kserve_gsa" {
  account_id   = "kserve-gsa"
  display_name = "KServe Model Reader"
  project      = var.project_id

  depends_on = [
    google_project.sue_project,
    time_sleep.wait_for_apis
  ]
}

#
# Allow the GSA to read model files
#
resource "google_storage_bucket_iam_member" "gcs_viewer" {
  bucket = google_storage_bucket.models.name
  role   = "roles/storage.objectViewer"

  member = "serviceAccount:${google_service_account.kserve_gsa.email}"
}

#
# Allow the VM's default compute SA to upload models
#

resource "google_storage_bucket_iam_member" "model_writer" {
  bucket = google_storage_bucket.models.name
  role   = "roles/storage.objectAdmin"

  member = "serviceAccount:${google_project.sue_project.number}-compute@developer.gserviceaccount.com"
}


