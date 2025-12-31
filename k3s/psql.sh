#!/bin/bash

set -e

# Helm repo setup
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL using Helm with flags
# Note: The drive used for local-path must support linux permissions (ext4, xfs, etc.)
helm upgrade --install psql bitnami/postgresql \
  --namespace "psql" \
  --create-namespace \
  --set primary.persistence.storageClass=local-path \
  --set primary.persistence.size=10Gi \
  --set primary.persistence.enabled=true \
  --set volumePermissions.enabled=true
