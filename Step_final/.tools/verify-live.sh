#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
DNS_DOH_URL=https://dns.quad9.net/dns-query bash scripts/project.sh verify
echo 'Argo CD HTTPS:'
curl --doh-url https://dns.quad9.net/dns-query --insecure --fail --silent --show-error -o ../.tools/argocd-live.html -w '%{http_code}\n' https://argocd.systemd.pp.ua/
kubectl -n argocd get applications
kubectl -n backend get deployment,pods,services,ingress
aws eks list-nodegroups --cluster-name freimaster --output json
