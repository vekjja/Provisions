#!/bin/bash

# 88888888ba    ad88888ba     ,ad8888ba,    88           
# 88      "8b  d8"     "8b   d8"'    `"8b   88           
# 88      ,8P  Y8,          d8'        `8b  88           
# 88aaaaaa8P'  `Y8aaaaa,    88          88  88           
# 88""""""'      `"""""8b,  88          88  88           
# 88                   `8b  Y8,    "88,,8P  88           
# 88           Y8a     a8P   Y8a.    Y88P   88           
# 88            "Y88888P"     `"Y8888Y"Y8a  88888888888  
                                                       

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
