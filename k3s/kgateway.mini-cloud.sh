#!/bin/bash
                                                                                                  
# 88      a8P   ,ad8888ba,         db    888888888888  88888888888  I8,        8        ,8I    db    8b        d8  
# 88    ,88'   d8"'    `"8b       d88b        88       88           `8b       d8b       d8'   d88b    Y8,    ,8P   
# 88  ,88"    d8'                d8'`8b       88       88            "8,     ,8"8,     ,8"   d8'`8b    Y8,  ,8P    
# 88,d88'     88                d8'  `8b      88       88aaaaa        Y8     8P Y8     8P   d8'  `8b    "8aa8"     
# 8888"88,    88      88888    d8YaaaaY8b     88       88"""""        `8b   d8' `8b   d8'  d8YaaaaY8b    `88'      
# 88P   Y8b   Y8,        88   d8""""""""8b    88       88              `8a a8'   `8a a8'  d8""""""""8b    88       
# 88     "88,  Y8a.    .a88  d8'        `8b   88       88               `8a8'     `8a8'  d8'        `8b   88       
# 88       Y8b  `"Y88888P"  d8'          `8b  88       88888888888       `8'       `8'  d8'          `8b  88       
                                                                                                                 
                                                                                         
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
  annotations:
    cert-manager.io/cluster-issuer: "cloudflare-letsencrypt-production"
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

    # Wildcard listener for livingroom.cloud
    - name: livingroom-cloud-wildcard
      protocol: HTTPS
      port: 443
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: auto-livingroom-cloud-tls

    # Dedicated HTTPS Listener for torch.cloud
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
          - name: auto-torch-cloud-tls
EOF
