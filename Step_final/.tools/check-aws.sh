#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
aws eks describe-cluster --name freimaster --query 'cluster.{status:status,version:version}' --output json
aws service-quotas get-service-quota --service-code ec2 --quota-code L-34B43A08 --query 'Quota.{name:QuotaName,vcpus:Value}' --output json || true
curl -fsS 'https://dns.google/resolve?name=systemd.pp.ua&type=NS'
echo
