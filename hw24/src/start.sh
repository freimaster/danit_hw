#!/bin/bash
set -e

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

kubectl rollout status deployment/python-random --timeout=60s

sleep 10

kubectl get pods -o wide
kubectl get svc -o wide

MINIKUBE_IP=$(kubectl get node minikube -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

for i in {1..10}; do
  curl "http://${MINIKUBE_IP}:30082"
  echo
done