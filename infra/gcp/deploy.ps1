Write-Host "=== Phase 1 ==="

Copy-Item shared\providers.tf phase1 -Force
Copy-Item shared\variables.tf phase1 -Force
Copy-Item shared\terraform.tfvars phase1\ -Force

terraform -chdir=phase1 init
terraform -chdir=phase1 apply -auto-approve

if ($LASTEXITCODE -ne 0) {
throw "Phase 1 failed."
}

$ProjectId = terraform -chdir=phase1 output -raw project_id
$Cluster   = terraform -chdir=phase1 output -raw cluster_name
$Region    = terraform -chdir=phase1 output -raw region
$KServeGsaEmail = terraform -chdir=phase1 output -raw kserve_gsa_email
$KServeGsaName  = terraform -chdir=phase1 output -raw kserve_gsa_name


Write-Host ""
Write-Host "Project: $ProjectId"
Write-Host "Cluster: $Cluster"
Write-Host "Region: $Region"
Write-Host  "kserve GSA Email: $KServeGsaEmail ($KServeGsaName)"
Write-Host "kserve GSA Name: $KServeGsaName"

Write-Host ""
Write-Host "Obtaining Kubernetes credentials..."

gcloud container clusters get-credentials $Cluster --region $Region --project $ProjectId

if ($LASTEXITCODE -ne 0) {
throw "Failed to obtain cluster credentials."
}

Write-Host ""
Write-Host "Waiting for Kubernetes API..."

$Ready = $false

do {
try {
kubectl get nodes | Out-Null
$Ready = $true
}
catch {
Write-Host "Kubernetes API not ready yet..."
Start-Sleep -Seconds 15
}
}
until ($Ready)

Write-Host "Kubernetes API Ready"

Write-Host ""
Write-Host "=== Phase 2 ==="

Copy-Item shared\providers.tf phase2 -Force
Copy-Item shared\variables.tf phase2 -Force
Copy-Item shared\terraform.tfvars phase2 -Force
Copy-Item shared-k8s\providers-k8s.tf phase2\ -Force

terraform -chdir=phase2 init
terraform -chdir=phase2 apply -auto-approve

if ($LASTEXITCODE -ne 0) {
throw "Phase 2 failed."
}

Write-Host ""
Write-Host "Waiting for KServe controller..."

Start-Sleep -Seconds 60

Write-Host ""
Write-Host "=== Phase 3 ==="

Copy-Item shared\providers.tf phase3 -Force
Copy-Item shared\variables.tf phase3 -Force
Copy-Item shared\terraform.tfvars phase3 -Force
Copy-Item shared-k8s\providers-k8s.tf phase3\ -Force

terraform -chdir=phase3 init
terraform -chdir=phase3 apply `
  -var="kserve_gsa_email=$KServeGsaEmail" `
  -var="kserve_gsa_name=$KServeGsaName" `
  -auto-approve

if ($LASTEXITCODE -ne 0) {
throw "Phase 3 failed."
}

Write-Host ""
Write-Host "======================================"
Write-Host "Deployment completed successfully"
Write-Host "======================================"
