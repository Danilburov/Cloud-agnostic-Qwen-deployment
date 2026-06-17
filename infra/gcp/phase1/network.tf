resource "google_compute_network" "vpc" {
  name                    = "sue-vpc"
  auto_create_subnetworks = false

  project = google_project.sue_project.project_id

  depends_on = [
    google_project_service.services,
    time_sleep.wait_for_apis
  ]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region

  network = google_compute_network.vpc.id
  project = google_project.sue_project.project_id
  depends_on = [
    google_project_service.services
  ]
}