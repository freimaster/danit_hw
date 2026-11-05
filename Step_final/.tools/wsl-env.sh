#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
cd "$(dirname "${BASH_SOURCE[0]}")/../project"
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  IFS='=' read -r name value <<< "$line"
  export "$name=$value"
done < .env
export TF_VAR_git_token="$GITHUB_TOKEN"
if [[ -n "${ARGOCD_ADMIN_PASSWORD:-}" ]]; then export TF_VAR_argocd_admin_password="$ARGOCD_ADMIN_PASSWORD"; fi
export AWS_PAGER=''
