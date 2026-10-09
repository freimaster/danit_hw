#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_NAMESPACE="gitlab-runner"
RUNNER_SETUP_DIR=""

cleanup() {
  unset RUNNER_AUTHENTICATION_TOKEN
  if [[ -n "$RUNNER_SETUP_DIR" ]]; then
    rm -rf -- "$RUNNER_SETUP_DIR"
  fi
}
trap cleanup EXIT

command -v kubectl >/dev/null
if [[ "$(kubectl config current-context)" != "minikube" ]]; then
  echo "Select the Minikube context: kubectl config use-context minikube" >&2
  exit 1
fi
kubectl get namespace stepproject4 >/dev/null

if command -v helm >/dev/null 2>&1; then
  HELM_BIN="$(command -v helm)"
else
  # Use a temporary Helm CLI; no system-wide installation is needed.
  for tool in curl tar sha256sum; do command -v "$tool" >/dev/null; done
  case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    aarch64) arch=arm64 ;;
    *) echo "Unsupported architecture" >&2; exit 1 ;;
  esac
  RUNNER_SETUP_DIR="$(mktemp -d)"
  archive="helm-v3.19.0-linux-$arch.tar.gz"
  curl -fsSLo "$RUNNER_SETUP_DIR/$archive" "https://get.helm.sh/$archive"
  curl -fsSLo "$RUNNER_SETUP_DIR/$archive.sha256sum" "https://get.helm.sh/$archive.sha256sum"
  (cd "$RUNNER_SETUP_DIR" && sha256sum -c "$archive.sha256sum")
  tar -xzf "$RUNNER_SETUP_DIR/$archive" -C "$RUNNER_SETUP_DIR"
  HELM_BIN="$RUNNER_SETUP_DIR/linux-$arch/helm"
fi

if [[ -z "${RUNNER_AUTHENTICATION_TOKEN:-}" ]]; then
  read -r -s -p 'Runner authentication token (glrt-...): ' RUNNER_AUTHENTICATION_TOKEN
  printf '\n'
fi
case "$RUNNER_AUTHENTICATION_TOKEN" in
  glrt-*) ;;
  *) echo "Use the authentication token from the existing Runner entry." >&2; exit 1 ;;
esac

kubectl create namespace "$RUNNER_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/runner/deploy-rbac.yaml"
# The token goes directly to a Kubernetes Secret, without appearing in argv or Git.
printf '%s' "$RUNNER_AUTHENTICATION_TOKEN" | \
  kubectl -n "$RUNNER_NAMESPACE" create secret generic gitlab-runner-auth \
    --from-file=runner-token=/dev/stdin \
    --from-literal=runner-registration-token= \
    --dry-run=client -o yaml | kubectl apply -f -
unset RUNNER_AUTHENTICATION_TOKEN

"$HELM_BIN" repo add gitlab https://charts.gitlab.io
"$HELM_BIN" repo update gitlab
"$HELM_BIN" upgrade --install gitlab-runner gitlab/gitlab-runner \
  --namespace "$RUNNER_NAMESPACE" \
  --values "$SCRIPT_DIR/runner/values.yaml" \
  --wait --timeout 5m

kubectl -n "$RUNNER_NAMESPACE" rollout status deployment/gitlab-runner --timeout=120s
kubectl -n "$RUNNER_NAMESPACE" exec deployment/gitlab-runner -- gitlab-runner verify
kubectl auth can-i patch deployments -n stepproject4 \
  --as=system:serviceaccount:gitlab-runner:gitlab-deployer
kubectl auth can-i create persistentvolumes \
  --as=system:serviceaccount:gitlab-runner:gitlab-deployer
kubectl -n "$RUNNER_NAMESPACE" get pods
echo "Runner is installed. Enable Run untagged jobs for this Runner in GitLab."
