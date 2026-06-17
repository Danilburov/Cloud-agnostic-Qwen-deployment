#!/bin/bash

set -e

read -p "Type DESTROY to continue: " confirmation

if [ "$confirmation" != "DESTROY" ]; then
    echo "Destroy cancelled."
    exit 0
fi

echo "Destroying Phase 3..."
terraform -chdir=phase3 destroy -auto-approve

echo "Destroying Phase 2..."
terraform -chdir=phase2 destroy -auto-approve

echo "Destroying Phase 1..."
terraform -chdir=phase1 destroy -auto-approve

echo "Destroy complete."