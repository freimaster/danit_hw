#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
for part in dns cluster platform; do
  set +e
  terraform -chdir="terraform/$part" plan -input=false -detailed-exitcode -no-color > "../.tools/idempotence-$part.log" 2>&1
  code=$?
  set -e
  tail -n 6 "../.tools/idempotence-$part.log"
  if [[ "$code" -ne 0 ]]; then echo "Unexpected plan exit $code for $part"; exit "$code"; fi
  echo "$part idempotence: PASS (no changes)"
done
