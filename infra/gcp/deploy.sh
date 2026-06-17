#!/bin/bash

set -e

echo "=== Phase 1 ==="

cp shared/providers.tf phase1/
cp shared/variables.tf phase1/
cp shared/terraform.tfvars phase1/

terraform -chdir=phase1 init
terraform -chdir=phase1 apply -auto-approve

PROJECT_ID=$(terraform -chdir=phase1 output -raw project_id)
CLUSTER=$(terraform -chdir=phase1 output -raw cluster_name)
REGION=$(terraform -chdir=phase1 output -raw region)
KSERVE_GSA_EMAIL=$(terraform -chdir=phase1 output -raw kserve_gsa_email)
KSERVE_GSA_NAME=$(terraform -chdir=phase1 output -raw kserve_gsa_name)

echo ""
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER"
echo "Region: $REGION"
echo "KServe GSA Email: $KSERVE_GSA_EMAIL"
echo "KServe GSA Name: $KSERVE_GSA_NAME"

echo ""
echo "Obtaining Kubernetes credentials..."

gcloud container clusters get-credentials \
  "$CLUSTER" \
  --region "$REGION" \
  --project "$PROJECT_ID"

echo ""
echo "Waiting for Kubernetes API..."

until kubectl get nodes >/dev/null 2>&1; do
    echo "Kubernetes API not ready yet..."
    sleep 15
done

echo "Kubernetes API Ready"

echo ""
echo "=== Phase 2 ==="

cp shared/providers.tf phase2/
cp shared/variables.tf phase2/
cp shared/terraform.tfvars phase2/
cp shared-k8s/providers-k8s.tf phase2/

terraform -chdir=phase2 init
terraform -chdir=phase2 apply -auto-approve

echo ""
echo "Waiting for KServe controller..."

sleep 60

echo ""
echo "=== Phase 3 ==="

cp shared/providers.tf phase3/
cp shared/variables.tf phase3/
cp shared/terraform.tfvars phase3/
cp shared-k8s/providers-k8s.tf phase3/

terraform -chdir=phase3 init

terraform -chdir=phase3 apply \
  -var="kserve_gsa_email=${KSERVE_GSA_EMAIL}" \
  -var="kserve_gsa_name=${KSERVE_GSA_NAME}" \
  -auto-approve

echo ""
echo "======================================"
echo "Deployment completed successfully"
echo "======================================"