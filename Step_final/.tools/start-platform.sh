#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
terraform -chdir=terraform/platform init -input=false -lockfile=readonly
terraform -chdir=terraform/platform plan -input=false -out=deploy.tfplan -no-color > ../.tools/platform-plan.log
tail -n 20 ../.tools/platform-plan.log
terraform -chdir=terraform/platform apply -input=false -no-color deploy.tfplan
