#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
kubectl get pods -A -o wide
kubectl get services -A
kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp
