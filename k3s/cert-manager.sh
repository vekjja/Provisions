#!/bin/bash

# ░█████╗░███████╗██████╗░████████╗░░░░░░███╗░░░███╗░█████╗░███╗░░██╗░█████╗░░██████╗░███████╗██████╗░
# ██╔══██╗██╔════╝██╔══██╗╚══██╔══╝░░░░░░████╗░████║██╔══██╗████╗░██║██╔══██╗██╔════╝░██╔════╝██╔══██╗
# ██║░░╚═╝█████╗░░██████╔╝░░░██║░░░█████╗██╔████╔██║███████║██╔██╗██║███████║██║░░██╗░█████╗░░██████╔╝
# ██║░░██╗██╔══╝░░██╔══██╗░░░██║░░░╚════╝██║╚██╔╝██║██╔══██║██║╚████║██╔══██║██║░░╚██╗██╔══╝░░██╔══██╗
# ╚█████╔╝███████╗██║░░██║░░░██║░░░░░░░░░██║░╚═╝░██║██║░░██║██║░╚███║██║░░██║╚██████╔╝███████╗██║░░██║
# ░╚════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░░░░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░╚═════╝░╚══════╝╚═╝░░╚═╝

# Install Cert Manager using Helm
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --set config.enableGatewayAPI=true

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  namespace: cert-manager
  name: cloudflare-api-token
type: Opaque
stringData:
  api-token: ${CLOUDFLARE_ACCOUNT_API_TOKEN}
---
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cloudflare-letsencrypt-production
spec:
  acme:
    email: seemywings@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cloudflare-issuer-account-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
---
EOF


# Certificate Issuer LetsEncrypt Staging
#
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-staging
# spec:
#   acme:
#     server: https://acme-staging-v02.api.letsencrypt.org/directory
#     email: seemywings@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-staging-issuer-key
#     solvers:
#       - http01:
#           ingress:
#             class: nginx
#             # ingress-nginx commonly enforces HTTP->HTTPS redirects (308). HTTP-01 requires plain HTTP 200
#             # on `/.well-known/acme-challenge/*`, so disable redirects on the solver ingress.
#             ingressTemplate:
#               metadata:
#                 annotations:
#                   nginx.ingress.kubernetes.io/ssl-redirect: "false"
#                   nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
# ---
# EOF

#
# Certificate Issuer LetsEncrypt Prod
#
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-prod
# spec:
#   acme:
#     server: https://acme-v02.api.letsencrypt.org/directory
#     email: seemywings@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-prod-issuer-key
#     solvers:
#       - http01:
#           ingress:
#             class: nginx
#             ingressTemplate:
#               metadata:
#                 annotations:
#                   nginx.ingress.kubernetes.io/ssl-redirect: "false"
#                   nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
# ---
# EOF

