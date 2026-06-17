resource "google_container_node_pool" "primary_nodes" {
  name       = "system-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = 1

  project = google_project.sue_project.project_id

  node_config {
    machine_type = var.machine_type

    disk_size_gb = 40
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}