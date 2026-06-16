#!/bin/bash

                                                                                                                                                                                
# 88888888888                                                                        88           ad88888ba                                                                       
# 88                          ,d                                                     88          d8"     "8b                                                    ,d                
# 88                          88                                                     88          Y8,                                                            88                
# 88aaaaa      8b,     ,d8  MM88MMM  ,adPPYba,  8b,dPPYba,  8b,dPPYba,   ,adPPYYba,  88          `Y8aaaaa,     ,adPPYba,   ,adPPYba,  8b,dPPYba,   ,adPPYba,  MM88MMM  ,adPPYba,  
# 88"""""       `Y8, ,8P'     88    a8P_____88  88P'   "Y8  88P'   `"8a  ""     `Y8  88  aaaaaaaa  `"""""8b,  a8P_____88  a8"     ""  88P'   "Y8  a8P_____88    88     I8[    ""  
# 88              )888(       88    8PP"""""""  88          88       88  ,adPPPPP88  88  """"""""        `8b  8PP"""""""  8b          88          8PP"""""""    88      `"Y8ba,   
# 88            ,d8" "8b,     88,   "8b,   ,aa  88          88       88  88,    ,88  88          Y8a     a8P  "8b,   ,aa  "8a,   ,aa  88          "8b,   ,aa    88,    aa    ]8I  
# 88888888888  8P'     `Y8    "Y888  `"Ybbd8"'  88          88       88  `"8bbdP"Y8  88           "Y88888P"    `"Ybbd8"'   `"Ybbd8"'  88           `"Ybbd8"'    "Y888  `"YbbdP"'  
                                                                                                                                                                                

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