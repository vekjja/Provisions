#!/bin/bash

                                                                                                                                        
#   ,ad8888ba,    88                                                                       88           88  88  88                        
#  d8"'    `"8b   88                                                                       88           ""  88  ""    ,d                  
# d8'        `8b  88                                                                       88               88        88                  
# 88          88  88,dPPYba,   ,adPPYba,   ,adPPYba,  8b,dPPYba,  8b       d8  ,adPPYYba,  88,dPPYba,   88  88  88  MM88MMM  8b       d8  
# 88          88  88P'    "8a  I8[    ""  a8P_____88  88P'   "Y8  `8b     d8'  ""     `Y8  88P'    "8a  88  88  88    88     `8b     d8'  
# Y8,        ,8P  88       d8   `"Y8ba,   8PP"""""""  88           `8b   d8'   ,adPPPPP88  88       d8  88  88  88    88      `8b   d8'   
#  Y8a.    .a8P   88b,   ,a8"  aa    ]8I  "8b,   ,aa  88            `8b,d8'    88,    ,88  88b,   ,a8"  88  88  88    88,      `8b,d8'    
#   `"Y8888Y"'    8Y"Ybbd8"'   `"YbbdP"'   `"Ybbd8"'  88              "8"      `"8bbdP"Y8  8Y"Ybbd8"'   88  88  88    "Y888      Y88'     
#                                                                                                                               d8'      
#                                                                                                                              d8'       

set -e

# Helm repo setup
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace observability


# Create Grafana admin credentials secret from AWS Secrets Manager using External Secrets Operator
cat <<EOF | kubectl apply -f -
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: grafana-admin-credentials
  namespace: observability
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: grafana-admin-credentials
    creationPolicy: Owner
    template:
      type: Opaque
  data:
    - secretKey: admin-user
      remoteRef:
        key: grafana-env
        property: admin-user
    - secretKey: admin-password
      remoteRef:
        key: grafana-env
        property: admin-password
EOF

# Install kube-prometheus-stack (includes Prometheus, Grafana, Alertmanager, Node Exporter, etc.)
# See values file for configuration
helm upgrade --install grafana prometheus-community/kube-prometheus-stack \
  --namespace "observability" \
  --create-namespace \
  --values ./k3s/helm/values/grafana.dev-node-0.values.yaml

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
