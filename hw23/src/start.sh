#!/bin/bash
set -e
VM_IP=$(hostname -I | awk '{print $1}')
MINIKUBE_IP=$(kubectl get node minikube -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=30080

if [ -z "$MINIKUBE_IP" ]; then
    echo "ERROR: Minikube IP not found"
    exit 1
fi

kubectl apply -f nginx-pod.yaml
kubectl apply -f nginx-service.yaml
kubectl wait --for=condition=Ready pod/nginx --timeout=60s
sleep 10
kubectl get pods -o wide
kubectl get svc -o wide

sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null

sudo iptables -t nat -D PREROUTING -p tcp -d "$VM_IP" --dport "$NODE_PORT" -j DNAT --to-destination "$MINIKUBE_IP:$NODE_PORT" 2>/dev/null || true
sudo iptables -D DOCKER-USER -p tcp -d "$MINIKUBE_IP" --dport "$NODE_PORT" -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -d "$MINIKUBE_IP" -p tcp --dport "$NODE_PORT" -j MASQUERADE 2>/dev/null || true

sudo iptables -t nat -A PREROUTING -p tcp -d "$VM_IP" --dport "$NODE_PORT" -j DNAT --to-destination "$MINIKUBE_IP:$NODE_PORT"
sudo iptables -I DOCKER-USER 1 -p tcp -d "$MINIKUBE_IP" --dport "$NODE_PORT" -j ACCEPT
sudo iptables -t nat -A POSTROUTING -d "$MINIKUBE_IP" -p tcp --dport "$NODE_PORT" -j MASQUERADE

sudo iptables -t nat -L -n -v