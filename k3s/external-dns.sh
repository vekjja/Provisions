#!/bin/bash

                                                                                                                                           
# 88888888888                                                                        88            88888888ba,    888b      88   ad88888ba   
# 88                          ,d                                                     88            88      `"8b   8888b     88  d8"     "8b  
# 88                          88                                                     88            88        `8b  88 `8b    88  Y8,          
# 88aaaaa      8b,     ,d8  MM88MMM  ,adPPYba,  8b,dPPYba,  8b,dPPYba,   ,adPPYYba,  88            88         88  88  `8b   88  `Y8aaaaa,    
# 88"""""       `Y8, ,8P'     88    a8P_____88  88P'   "Y8  88P'   `"8a  ""     `Y8  88  aaaaaaaa  88         88  88   `8b  88    `"""""8b,  
# 88              )888(       88    8PP"""""""  88          88       88  ,adPPPPP88  88  """"""""  88         8P  88    `8b 88          `8b  
# 88            ,d8" "8b,     88,   "8b,   ,aa  88          88       88  88,    ,88  88            88      .a8P   88     `8888  Y8a     a8P  
# 88888888888  8P'     `Y8    "Y888  `"Ybbd8"'  88          88       88  `"8bbdP"Y8  88            88888888Y"'    88      `888   "Y88888P"   
                                                                                                                                           
                                                                                                                                           

# Install ExternalDNS (official chart) for Cloudflare
# Requires environment variable CLOUDFLARE_API_TOKEN (DNS edit scope for the zone)

set -euo pipefail

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

# Namespace and secret
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -

# Create secret for Cloudflare API token
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="${CLOUDFLARE_ACCOUNT_API_TOKEN:?CLOUDFLARE_ACCOUNT_API_TOKEN required}" \
  -n external-dns \
  --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade ExternalDNS (official chart)
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --values ./k3s/helm/values/external-dns.values.yaml 


# Example DNSEndpoint
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: externaldns.k8s.io/v1alpha1
# kind: DNSEndpoint
# metadata:
#   name: example-livingroom-cloud-dns
#   namespace: external-dns
# spec:
#   endpoints:
#   - dnsName: example.livingroom.cloud
#     recordType: A
#     recordTTL: 300
#     targets: [ "174.44.105.210" ]
# ---
# EOF