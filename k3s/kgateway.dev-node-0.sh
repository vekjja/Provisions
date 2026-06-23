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

# Bind the Envoy proxy to the node network so ports 80/443 are reachable on the EC2 EIP.
# hostNetwork forbids pod sysctls; set net.ipv4.ip_unprivileged_port_start=0 on the node
# (see k3s.tuning.extra_sysctls in dev-node-0 host vars).
# https://kgateway.dev/docs/envoy/latest/setup/customize/configs/
kubectl apply -f- <<EOF
apiVersion: gateway.kgateway.dev/v1alpha1
kind: GatewayParameters
metadata:
  name: host-network
  namespace: kgateway-system
spec:
  kube:
    omitDefaultSecurityContext: true
    deploymentOverlay:
      spec:
        template:
          spec:
            hostNetwork: true
            dnsPolicy: ClusterFirstWithHostNet
    service:
      type: ClusterIP
EOF

# Gateway + HTTPRoute ingress for dev-node-0 (single-node k3s, no cloud LB).
# cert-manager requires hostname on HTTPS listeners:
# https://cert-manager.io/docs/usage/gateway/
kubectl apply -f- <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: http-gateway
  namespace: kgateway-system
  annotations:
    external-dns.alpha.kubernetes.io/target: "52.200.204.147"
    cert-manager.io/cluster-issuer: "cloudflare-letsencrypt-production"
spec:
  gatewayClassName: kgateway
  infrastructure:
    parametersRef:
      name: host-network
      group: gateway.kgateway.dev
      kind: GatewayParameters
  listeners:
    - name: http-all
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: authriz-io-wildcard
      protocol: HTTPS
      port: 443
      hostname: "*.authriz.io"
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: auto-authriz-io-tls
EOF
