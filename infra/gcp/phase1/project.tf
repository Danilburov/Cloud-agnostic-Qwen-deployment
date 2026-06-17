resource "google_project" "sue_project" {
  name            = var.project_name
  project_id      = var.project_id
  org_id          = var.org_id
  billing_account = var.billing_account

  deletion_policy = "DELETE"
}

resource "google_project_service" "services" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com"
  ])

  project            = google_project.sue_project.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "time_sleep" "wait_for_apis" {
  depends_on = [google_project_service.services]

  create_duration = "120s"
}