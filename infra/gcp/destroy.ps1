$confirmation = Read-Host "Type DESTROY to continue"

if ($confirmation -ne "DESTROY") {
Write-Host "Destroy cancelled."
exit
}

Write-Host "Destroying Phase 3..."
terraform -chdir=phase3 destroy -auto-approve

Write-Host "Destroying Phase 2..."
terraform -chdir=phase2 destroy -auto-approve

Write-Host "Destroying Phase 1..."
terraform -chdir=phase1 destroy -auto-approve

Write-Host "Destroy complete."
