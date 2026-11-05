#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    IFS='=' read -r name value <<< "$line"
    [[ "$name" =~ ^[A-Z][A-Z0-9_]*$ && "$line" == *=* ]] || { echo 'Invalid .env line' >&2; exit 1; }
    export "$name=$value"
  done < .env
fi
if [[ -n "${GITHUB_TOKEN:-}" ]]; then export TF_VAR_git_token="$GITHUB_TOKEN"; fi
if [[ -n "${ARGOCD_ADMIN_PASSWORD:-}" ]]; then export TF_VAR_argocd_admin_password="$ARGOCD_ADMIN_PASSWORD"; fi
export AWS_PAGER=''

context() {
  aws eks update-kubeconfig \
    --name "$(terraform -chdir=terraform/cluster output -raw cluster_name)" \
    --region "$(terraform -chdir=terraform/cluster output -raw aws_region)"
}

action="${1:-}"
approval=()
if [[ "${2:-}" == '--auto-approve' ]]; then approval=(-auto-approve); fi
case "$action" in
  dns)
    terraform -chdir=terraform/dns init -input=false -lockfile=readonly
    terraform -chdir=terraform/dns apply "${approval[@]}"
    terraform -chdir=terraform/dns output name_servers
    ;;
  validate)
    python3 -m unittest discover -s tests -v
    for part in dns cluster platform; do
      terraform -chdir="terraform/$part" fmt -check
      terraform -chdir="terraform/$part" init -backend=false -input=false -lockfile=readonly
      terraform -chdir="terraform/$part" validate
    done
    terraform -chdir=terraform/argocd-password fmt -check -recursive
    terraform -chdir=terraform/argocd-password init -backend=false -input=false
    terraform -chdir=terraform/argocd-password test
    helm lint argocd
    kubectl kustomize k8s
    ;;
  apply)
    [[ "${ARGOCD_ADMIN_PASSWORD:-}" =~ ^[!-~]{12,72}$ ]] || { echo 'Set ARGOCD_ADMIN_PASSWORD in .env: 12-72 ASCII characters without whitespace.' >&2; exit 1; }
    [[ -f terraform/cluster/terraform.tfvars ]] || { echo 'Create cluster terraform.tfvars and set admin_cidrs.' >&2; exit 1; }
    if grep -Eq 'newTag:[[:space:]]*bootstrap' k8s/kustomization.yaml; then
      echo 'Wait for successful image publication in GitHub Actions, then git pull --ff-only.' >&2
      exit 1
    fi
    for part in dns cluster platform; do
      terraform -chdir="terraform/$part" init -input=false -lockfile=readonly
      terraform -chdir="terraform/$part" apply "${approval[@]}"
    done
    context
    terraform -chdir=terraform/platform output
    echo 'Delegate DNS to name_servers, then run: bash scripts/project.sh verify'
    ;;
  verify)
    context
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    node_count="$(kubectl get nodes -o name | wc -l)"
    [[ "$node_count" -eq 1 ]] || { echo 'Expected exactly one node.' >&2; exit 1; }
    kubectl -n argocd wait application/backend '--for=jsonpath={.status.sync.status}=Synced' --timeout=600s
    kubectl -n argocd wait application/backend '--for=jsonpath={.status.health.status}=Healthy' --timeout=600s
    kubectl -n backend rollout status deployment/backend --timeout=300s
    curl_args=(--fail --show-error --silent --connect-timeout 10 --max-time 30)
    if [[ -n "${DNS_DOH_URL:-}" ]]; then curl_args+=(--doh-url "$DNS_DOH_URL"); fi
    response="$(curl "${curl_args[@]}" -w $'\n%{http_code}' "$(terraform -chdir=terraform/platform output -raw app_url)/")"
    status="${response##*$'\n'}"
    [[ "$status" == 200 ]] || { echo "Expected HTTP 200, received $status" >&2; exit 1; }
    printf '%s\n' "${response%$'\n'*}"
    echo
    echo 'One Ready node, Argo CD Synced/Healthy, backend HTTP 200.'
    ;;
  destroy)
    for part in platform cluster dns; do
      if [[ -f "terraform/$part/terraform.tfstate" ]]; then
        terraform -chdir="terraform/$part" init -input=false -lockfile=readonly
        remaining="$(terraform -chdir="terraform/$part" state list)"
        if ! grep -qvE '(^|\.)data\.|^$' <<< "$remaining"; then continue; fi
        terraform -chdir="terraform/$part" destroy "${approval[@]}"
      fi
    done
    ;;
  *) echo 'Usage: bash scripts/project.sh {dns|validate|apply|verify|destroy} [--auto-approve]' >&2; exit 2 ;;
esac
