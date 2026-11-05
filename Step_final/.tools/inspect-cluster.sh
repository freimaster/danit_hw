#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
aws eks update-kubeconfig --name freimaster --region eu-central-1
kubectl get nodes -o wide
nodegroup="$(aws eks list-nodegroups --cluster-name freimaster --query 'nodegroups[0]' --output text)"
aws eks describe-nodegroup --cluster-name freimaster --nodegroup-name "$nodegroup" --query 'nodegroup.{status:status,health:health,capacityType:capacityType,scalingConfig:scalingConfig}' --output json
