#!/usr/bin/env bash
set -e

echo "=== BRy - Desafio SRE ==="

# Criar cluster k3d
k3d cluster create sre-lab --servers 1 --agents 2 --wait || true
kubectl config use-context k3d-sre-lab

# Namespace
kubectl create ns sre || true

# Deploy whoami
kubectl apply -f k8s/base/whoami-deployment.yaml
kubectl apply -f k8s/base/whoami-service.yaml
kubectl apply -f k8s/base/ingress.yaml
kubectl apply -f k8s/base/networkpolicy.yaml
kubectl apply -f k8s/base/prometheus-rule.yaml

echo "=== Deploy finalizado! ==="
