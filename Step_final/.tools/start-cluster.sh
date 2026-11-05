#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
terraform -chdir=terraform/cluster init -input=false -lockfile=readonly
terraform -chdir=terraform/cluster plan -input=false -out=deploy.tfplan -no-color > ../.tools/wsl-cluster-plan.log
tail -n 15 ../.tools/wsl-cluster-plan.log
terraform -chdir=terraform/cluster apply -input=false -no-color deploy.tfplan
