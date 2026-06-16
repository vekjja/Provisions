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
  --set extraArgs={--enable-gateway-api}

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  namespace: cert-manager
  name: cloudflare-api-token
type: Opaque
stringData:
  api-token: ${CLOUDFLARE_API_TOKEN}
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

# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: cloudflare-letsencrypt-staging
# spec:
#   acme:
#     email: seemywings@gmail.com
#     server: https://acme-staging-v02.api.letsencrypt.org/directory
#     privateKeySecretRef:
#       name: cloudflare-issuer-account-key
#     solvers:
#     - dns01:
#         cloudflare:
#           apiTokenSecretRef:
#             name: cloudflare-api-token
#             key: api-token
# ---
# EOF

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

# Example Certificate resource for cert-manager
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: example-livingroom-cloud-certificate
#   namespace: default
# spec:
#   secretName: example-livingroom-cloud-tls
#   issuerRef:
#     name: cloudflare-letsencrypt-production
#     kind: ClusterIssuer
#   privateKey:
#     rotationPolicy: Always
#     algorithm: RSA
#     size: 2048
#   dnsNames:
#   - example.livingroom.cloud
# ---
# EOF

#
# Example Ingress Config
#
# cat <<EOF | kubectl apply -n test -f -
# ---
# apiVersion: extensions/v1
# kind: Ingress
# metadata:
#   name: example-livingroom-cloud-ingress
#   annotations:
#     kubernetes.io/ingress.class: "nginx"
#     cert-manager.io/cluster-issuer: "cloudflare-letsencrypt-staging"
#     external-dns.alpha.kubernetes.io/hostname: example.livingroom.cloud
#     external-dns.alpha.kubernetes.io/target: "174.44.105.210"
# spec:
#   tls:
#   - hosts:
#     - example.livingroom.cloud
#     secretName: "example.livingroom.cloud-staging-tls"
#   rules:
#   - host: example.livingroom.cloud
#     http:
#       paths:
#         - path: /
#           backend:
#             serviceName: nginx-test
#             servicePort: 80
# ---
# EOF
