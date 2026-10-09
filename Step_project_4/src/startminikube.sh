#!/bin/bash
set -e

NAMESPACE="stepproject4"
REGISTRY="192.168.1.182:5050"

minikube start \
  --driver=docker \
  --insecure-registry="$REGISTRY"

kubectl create namespace "$NAMESPACE" 2>/dev/null || true

kubectl -n "$NAMESPACE" delete secret gitlab-registry 2>/dev/null || true

kubectl -n "$NAMESPACE" create secret generic gitlab-registry \
  --from-file=.dockerconfigjson="$HOME/.docker/config.json" \
  --type=kubernetes.io/dockerconfigjson

minikube status
kubectl get nodes -o wide
kubectl -n "$NAMESPACE" get secrets
minikube ip