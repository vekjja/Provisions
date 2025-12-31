#!/bin/bash

set -e

# Helm repo setup
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace observability

# Create Grafana admin credentials secret
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-credentials
  namespace: observability
type: Opaque
data:
  admin-user: $(echo -n "admin" | base64)
  admin-password: $(echo -n "n0JKYORwlxl220ZsdkjN1lWABCnvRn0+S7b2cBNccgQ=" | base64)
EOF

# Install kube-prometheus-stack (includes Prometheus, Grafana, Alertmanager, Node Exporter, etc.)
# See values file for configuration
helm upgrade --install grafana prometheus-community/kube-prometheus-stack \
  --namespace "observability" \
  --create-namespace \
  --values ./k3s/helm/values/grafana.values.yaml

# Install Loki for logging
# See values file for configuration
helm upgrade --install loki grafana/loki \
  --namespace "observability" \
  --values ./k3s/helm/values/loki.values.yaml

# Install Grafana Alloy for log collection (replaced Promtail)
# It automatically discovers and collects logs from all pods in all namespaces
# It runs as a DaemonSet and uses Kubernetes service discovery to find pods
helm upgrade --install alloy grafana/alloy \
  --namespace "observability" \
  --values ./k3s/helm/values/alloy.values.yaml
