resource "google_compute_instance" "model_builder" {
  name         = "model-builder"
  project      = var.project_id
  machine_type = var.machine_type
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 50
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  metadata_startup_script = <<-EOT
#!/bin/bash
set -euxo pipefail

sudo apt-get update
sudo apt-get install -y python3-pip python3-venv git git-lfs

python3 -m venv /tmp/hf-env
source /tmp/hf-env/bin/activate

pip install -U huggingface_hub

hf download Qwen/Qwen2.5-0.5B-Instruct --local-dir /tmp/qwen

gcloud storage cp --recursive /tmp/qwen gs://${var.project_id}-models/qwen2.5-0.5b

shutdown -h now
EOT
}

resource "time_sleep" "wait_for_model_upload" {
  create_duration = "15m"

  depends_on = [
    google_compute_instance.model_builder
  ]
}