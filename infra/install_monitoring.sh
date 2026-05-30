#!/bin/bash

echo "🚀 Starting Monitoring Stack Installation (Prometheus & Grafana)..."

# 1. Add Helm Repo
echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Install/Upgrade Monitoring Stack
echo "Installing kube-prometheus-stack..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring-values.yaml \
  --timeout 15m0s

echo "------------------------------------------------------------"
echo "✅ Monitoring Installation Started!"
echo "------------------------------------------------------------"
echo "Waiting for LoadBalancer URL for Grafana..."
sleep 30
URL=$(kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Grafana URL: http://$URL"
echo "Username: admin"
# Retrieve default password
PASS=$(kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d)
echo "Password: $PASS"
echo "------------------------------------------------------------"
