#!/bin/bash

set -e

echo "======================================"
echo "NUKE MODE"
echo "======================================"
echo ""
echo "This will remove:"
echo "  - .terraform directories"
echo "  - .terraform.lock.hcl files"
echo "  - terraform.tfstate files"
echo "  - terraform.tfstate.backup files"
echo ""

read -p "Type NUKE to continue: " CONFIRM

if [ "$CONFIRM" != "NUKE" ]; then
echo "Cancelled."
exit 0
fi

for phase in phase1 phase2 phase3
do
echo ""
echo "Cleaning $phase..."

```
rm -rf "$phase/.terraform"
rm -f "$phase/.terraform.lock.hcl"

rm -f "$phase/terraform.tfstate"
rm -f "$phase/terraform.tfstate.backup"

rm -f "$phase/crash.log"
```

done

echo ""
echo "Cleanup complete."
echo ""
echo "NOTE:"
echo "Resources in GCP are NOT destroyed."
echo "Only local Terraform state was removed."
echo ""
echo "If resources still exist in GCP, run destroy.ps1 first."
