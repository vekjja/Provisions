#!/bin/bash
                                                                                                  
# `..   `..     `....         `.       `... `......`........`..        `..      `.       `..      `..
# `..  `..    `.    `..      `. ..          `..    `..      `..        `..     `. ..      `..    `.. 
# `.. `..    `..            `.  `..         `..    `..      `..   `.   `..    `.  `..      `.. `..   
# `. `.      `..           `..   `..        `..    `......  `..  `..   `..   `..   `..       `..     
# `..  `..   `..   `....  `...... `..       `..    `..      `.. `. `.. `..  `...... `..      `..     
# `..   `..   `..    `.  `..       `..      `..    `..      `. `.    `.... `..       `..     `..     
# `..     `..  `.....   `..         `..     `..    `........`..        `..`..         `..    `..     
                                                                                                   
                                                                                         
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


# Create Certs for kgateway
cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-livingroom-cloud
  namespace: kgateway-system # Must be in the same namespace as the Gateway
spec:
  secretName: wildcard-livingroom-cloud-tls # Matches the certificateRefs name in your Gateway
  issuerRef:
    name: cloudflare-letsencrypt-production
    kind: ClusterIssuer
  dnsNames:
    - "*.livingroom.cloud"
    - "livingroom.cloud"
---
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-torch-cloud
  namespace: kgateway-system # Must be in the same namespace as the Gateway
spec:
  secretName: wildcard-torch-cloud-tls # Matches the certificateRefs name in your Gateway
  issuerRef:
    name: cloudflare-letsencrypt-production
    kind: ClusterIssuer
  dnsNames:
    - "*.torch.cloud"
    - "torch.cloud"
---
EOF

# Create a Gateway resource and configure an HTTP listener. 
# The following Gateway can serve HTTPRoute resources from all namespaces.
kubectl apply -f- <<EOF
  kind: Gateway
  apiVersion: gateway.networking.k8s.io/v1
  metadata:
    name: http-gateway
    namespace: kgateway-system
    annotations:
      external-dns.alpha.kubernetes.io/target: "174.44.105.210"
  spec:
    gatewayClassName: kgateway
    listeners:
      # 1. Clear HTTP Listener
      - name: http-all
        protocol: HTTP
        port: 80
        allowedRoutes:
          namespaces:
            from: All
  
      # 2. Consolidated HTTPS Listener for ALL livingroom.cloud domains
      - name: livingroom-cloud-https
        protocol: HTTPS
        port: 443
        allowedRoutes:
          namespaces:
            from: All
        tls:
          mode: Terminate
          certificateRefs:
            - name: wildcard-livingroom-cloud-tls
  
      # 3. Dedicated HTTPS Listener for torch.cloud
      - name: torch-cloud-https
        protocol: HTTPS
        port: 443
        hostname: "torch.cloud"
        allowedRoutes:
          namespaces:
            from: All
        tls:
          mode: Terminate
          certificateRefs:
            - name: wildcard-torch-cloud-tls
EOF


# Example HTTPRoute to verify that the Gateway is working as expected.
# kubectl apply -f- <<EOF
# apiVersion: gateway.networking.k8s.io/v1
# kind: HTTPRoute
# metadata:
#   name: torch-cloud
#   namespace: torch-cloud
# spec:
#   parentRefs:
#     - name: http
#       namespace: kgateway-system
#   hostnames:
#     - "torch.cloud"
#   rules:
#     - backendRefs:
#         - name: torch-cloud
#           port: 3000
# EOF