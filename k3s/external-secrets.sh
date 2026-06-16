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


# Enable GCP Secret Manager API and create GCP SA
GCLOUD_PROJECT=living-room-cloud
gcloud --project=${GCLOUD_PROJECT} services enable secretmanager.googleapis.com
gcloud --project=${GCLOUD_PROJECT} iam service-accounts create external-secrets
gcloud projects add-iam-policy-binding ${GCLOUD_PROJECT} \
  --member="serviceAccount:external-secrets@${GCLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Create GCP SA key
gcloud iam service-accounts keys create gcp-eso-key.json \
  --iam-account=external-secrets@${GCLOUD_PROJECT}.iam.gserviceaccount.com

# Create Kubernetes secret from GCP SA key
GCP_SA_KEY_FILE="${GCP_SA_KEY_FILE:-./gcp-eso-key.json}"
[[ -f "${GCP_SA_KEY_FILE}" ]] || { echo "GCP SA key file not found: ${GCP_SA_KEY_FILE}" >&2; exit 1; }

kubectl create secret generic gcp-secret-manager-credentials \
  --from-file=secret-access-credentials="${GCP_SA_KEY_FILE}" \
  -n external-secrets \
  --dry-run=client -o yaml | kubectl apply -f -

rm ${GCP_SA_KEY_FILE}

# GCP SecretStore
cat <<EOF | kubectl apply -f -
---
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: gcp-secret-manager
spec:
  provider:
    gcpsm:
      projectID: living-room-cloud
      auth:
        secretRef:
          secretAccessKeySecretRef:
            name: gcp-secret-manager-credentials
            key: secret-access-credentials
            namespace: external-secrets
EOF