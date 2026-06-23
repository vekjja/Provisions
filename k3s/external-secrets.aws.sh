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
#
# AWS prerequisites (managed in condensation/stacks/Dev.ts):
#   - IAM user: dev-external-secrets
#   - Policy: dev-infra-ExternalSecretsAccess (Secrets Manager read)
#   - Access key + credentials secret: dev-external-secrets/credentials
# Deploy CDK before running this script.

set -euo pipefail

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true


# AWS credentials for External Secrets Operator (separate from AWS CLI env vars)
EXTERNAL_SECRETS_CREDENTIALS_SECRET="dev-external-secrets/credentials"

if [[ -z "${ESO_ACCESS_KEY_ID:-}" || -z "${ESO_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Fetching credentials from Secrets Manager (${EXTERNAL_SECRETS_CREDENTIALS_SECRET})..."
  CREDS_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "${EXTERNAL_SECRETS_CREDENTIALS_SECRET}" \
    --query SecretString --output text)
  ESO_ACCESS_KEY_ID=$(jq -r .accessKeyId <<< "$CREDS_JSON")
  ESO_SECRET_ACCESS_KEY=$(jq -r .secretAccessKey <<< "$CREDS_JSON")
fi

kubectl create secret generic aws-secrets-manager-credentials \
  --from-literal=access-key-id="${ESO_ACCESS_KEY_ID}" \
  --from-literal=secret-access-key="${ESO_SECRET_ACCESS_KEY}" \
  -n external-secrets \
  --dry-run=client -o yaml | kubectl apply -f -

# AWS Secrets Manager ClusterSecretStore
cat <<EOF | kubectl apply -f -
---
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-secrets-manager-credentials
            key: access-key-id
            namespace: external-secrets
          secretAccessKeySecretRef:
            name: aws-secrets-manager-credentials
            key: secret-access-key
            namespace: external-secrets
EOF
