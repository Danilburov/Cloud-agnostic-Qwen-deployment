resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  project = google_project.sue_project.project_id

  node_config {
    machine_type = "e2-standard-2"

    disk_size_gb = 40
    disk_type    = "pd-standard"
  }

  workload_identity_config {
    workload_pool = "${google_project.sue_project.project_id}.svc.id.goog"
  }

  depends_on = [time_sleep.wait_for_apis]
}