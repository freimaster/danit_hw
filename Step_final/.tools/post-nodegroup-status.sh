#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
aws eks list-nodegroups --cluster-name freimaster --output json
aws ec2 describe-launch-templates --query 'LaunchTemplates[].{id:LaunchTemplateId,name:LaunchTemplateName}' --output json
aws eks describe-cluster --name freimaster --query 'cluster.status' --output text
