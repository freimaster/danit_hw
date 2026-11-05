#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
sed -i 's/capacity_type[[:space:]]*=[[:space:]]*"SPOT"/capacity_type = "ON_DEMAND"/' terraform/cluster/terraform.tfvars
terraform -chdir=terraform/cluster fmt
terraform -chdir=terraform/cluster plan -input=false -out=deploy.tfplan -no-color > ../.tools/cluster-retry-plan.log
tail -n 25 ../.tools/cluster-retry-plan.log
terraform -chdir=terraform/cluster apply -input=false -no-color deploy.tfplan
