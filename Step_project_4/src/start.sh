#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
NAMESPACE="stepproject4"
APP_IMAGE="192.168.1.182:5050/root/stepproject4/flask-mysql"

if [ "$#" -gt 1 ]; then
  echo "Usage: sh start.sh [image:tag]" >&2
  exit 1
fi

# Namespace and registry credentials are created by startminikube.sh.
kubectl get namespace "$NAMESPACE" >/dev/null
kubectl -n "$NAMESPACE" get secret gitlab-registry >/dev/null

if [ "$#" -eq 1 ]; then
  IMAGE="$1"
else
  minikube status
  IMAGE="$APP_IMAGE:local-$(date +%s)-$$"
  docker buildx build --provenance=false --sbom=false --load \
    -t "$IMAGE" "$SCRIPT_DIR/forStep4"
  minikube image load "$IMAGE"
fi

kubectl apply -f "$SCRIPT_DIR/k8s/storage.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/mysql.yaml"
# The original application connects during import, so wait for MySQL first.
kubectl -n "$NAMESPACE" rollout status deployment/mysql --timeout=300s
kubectl set image --local -f "$SCRIPT_DIR/k8s/app-deployment.yaml" \
  flask-app="$IMAGE" -o yaml | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/k8s/app-service.yaml"
kubectl -n "$NAMESPACE" rollout status deployment/flask-app --timeout=120s
kubectl -n "$NAMESPACE" get pods -o wide
kubectl -n "$NAMESPACE" get services -o wide
kubectl get pv mysql-pv
kubectl -n "$NAMESPACE" get pvc mysql-pvc

if command -v minikube >/dev/null 2>&1; then
  printf 'Pet Shop: http://%s:30080/\n' "$(minikube ip)"
fi
