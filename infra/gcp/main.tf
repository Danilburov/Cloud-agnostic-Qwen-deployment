provider "google" {
  region      = "europe-west4"
}

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
    "iam.googleapis.com"
  ])

  project = google_project.sue_project.project_id
  service = each.key
}

resource "google_compute_network" "vpc" {
  name                    = "sue-vpc"
  auto_create_subnetworks = false

  project = google_project.sue_project.project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region

  network = google_compute_network.vpc.id
  project = google_project.sue_project.project_id
}

resource "google_container_cluster" "gke" {
  name     = "sue-cluster"
  location = var.region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  project = google_project.sue_project.project_id
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "system-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = 2

  project = google_project.sue_project.project_id

  node_config {
    machine_type = "e2-standard-4"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}