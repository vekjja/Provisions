# Create image pull secret in namespace 
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=vekjja \
  --docker-password=$GITHUB_PAT \
  -n default