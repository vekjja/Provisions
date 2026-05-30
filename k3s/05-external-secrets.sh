#!/bin/bash

# Install External Secrets Operator (official chart)
# https://external-secrets.io/latest/introduction/getting-started/

set -euo pipefail

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --values ./k3s/helm/values/external-secrets.values.yaml