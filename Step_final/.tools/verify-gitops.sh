#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
expected=a458f0ed6b444197006a1a273e4df7d112f18039
for attempt in {1..40}; do
  body="$(curl --doh-url https://dns.quad9.net/dns-query --fail --silent --show-error --max-time 20 http://app.systemd.pp.ua/ || true)"
  version="$(printf '%s' "$body" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("version", ""))' 2>/dev/null || true)"
  if [[ "$version" == "$expected" ]]; then
    printf '%s\n' "$body"
    kubectl -n argocd wait application/backend '--for=jsonpath={.status.sync.status}=Synced' --timeout=180s
    kubectl -n argocd wait application/backend '--for=jsonpath={.status.health.status}=Healthy' --timeout=180s
    kubectl -n backend rollout status deployment/backend --timeout=180s
    kubectl -n backend get deployment/backend -o jsonpath='{.spec.template.spec.containers[0].image}'
    echo
    kubectl get nodes -L node.kubernetes.io/instance-type
    echo 'GitOps automatic image rollout: PASS'
    exit 0
  fi
  echo "Waiting for CI and Argo CD auto-sync (attempt $attempt, current version $version)"
  sleep 15
done
echo 'GitOps rollout timed out' >&2
exit 1
