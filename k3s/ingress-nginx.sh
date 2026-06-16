#!/bin/bash

# ██╗███╗░░██╗░██████╗░██████╗░███████╗░██████╗░██████╗░░░░░░███╗░░██╗░██████╗░██╗███╗░░██╗██╗░░██╗
# ██║████╗░██║██╔════╝░██╔══██╗██╔════╝██╔════╝██╔════╝░░░░░░████╗░██║██╔════╝░██║████╗░██║╚██╗██╔╝
# ██║██╔██╗██║██║░░██╗░██████╔╝█████╗░░╚█████╗░╚█████╗░█████╗██╔██╗██║██║░░██╗░██║██╔██╗██║░╚███╔╝░
# ██║██║╚████║██║░░╚██╗██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗╚════╝██║╚████║██║░░╚██╗██║██║╚████║░██╔██╗░
# ██║██║░╚███║╚██████╔╝██║░░██║███████╗██████╔╝██████╔╝░░░░░░██║░╚███║╚██████╔╝██║██║░╚███║██╔╝╚██╗
# ╚═╝╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░░░░░░░╚═╝░░╚══╝░╚═════╝░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝
# Official Kubernetes Ingress: https://kubernetes.github.io/ingress-nginx/deploy/

# Install Ingress Nginx using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Ingress NGINX defaults to redirecting HTTP->HTTPS (308) when TLS is configured for a host.
# That behavior can break ACME HTTP-01 challenges, which require a plain HTTP 200 response on:
#   http://<host>/.well-known/acme-challenge/<token>
# If you prefer redirect-by-default for apps, remove these and instead disable redirects only on
# specific ingresses using annotations:
#   nginx.ingress.kubernetes.io/ssl-redirect: "false"
#   nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
  
  # --set controller.config.ssl-redirect="false" \
  # --set controller.config.force-ssl-redirect="false"

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --selector=app.kubernetes.io/component=controller \
  --for=condition=ready pod \
  --timeout=120s

# View LoadBalancer External IP
kubectl get service ingress-nginx-controller --namespace=ingress-nginx

