#!/bin/bash

# Install KGateway (official chart)
# https://kgateway.dev/docs/envoy/main/install/helm/

set -euo pipefail

# Install the kgateway control plane by using Helm.
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml

KGATEWAY_VERSION="v2.4.0-main"

# Apply the kgateway CRDs for the upgrade version by using Helm.
helm upgrade --install \
  --create-namespace \
  --namespace kgateway-system \
  --version ${KGATEWAY_VERSION} kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds 

# Install the kgateway Helm chart.
helm upgrade --install kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
  --namespace kgateway-system \
  --version ${KGATEWAY_VERSION} \
  -f ./k3s/helm/values/kgateway.values.yaml


# Create a Gateway resource and configure an HTTP listener. 
# The following Gateway can serve HTTPRoute resources from all namespaces.
kubectl apply -f- <<EOF
    kind: Gateway
    apiVersion: gateway.networking.k8s.io/v1
    metadata:
      name: http-gateway
      namespace: kgateway-system
    spec:
      gatewayClassName: kgateway
      listeners:
      - protocol: HTTP
        port: 8080
        name: http
        allowedRoutes:
          namespaces:
            from: All
EOF


# Add a test HTTPRoute to verify that the Gateway is working as expected.
kubectl apply -f- <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: torch-cloud
  namespace: torch-cloud
spec:
  parentRefs:
    - name: http
      namespace: kgateway-system
  hostnames:
    - "torch.cloud"
  rules:
    - backendRefs:
        - name: httpbin
          port: 8000
EOF