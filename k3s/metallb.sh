#!/bin/bash

# ███╗░░░███╗███████╗████████╗░█████╗░██╗░░░░░██╗░░░░░██████╗░
# ████╗░████║██╔════╝╚══██╔══╝██╔══██╗██║░░░░░██║░░░░░██╔══██╗
# ██╔████╔██║█████╗░░░░░██║░░░███████║██║░░░░░██║░░░░░██████╦╝
# ██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██║░░░░░██║░░░░░██╔══██╗
# ██║░╚═╝░██║███████╗░░░██║░░░██║░░██║███████╗███████╗██████╦╝
# ╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═════╝░
#
# https://metallb.universe.tf/installation/


# Install Metallb using Helm
helm repo add metallb https://metallb.github.io/metallb
helm repo update

helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace

# Create MetalLB Address Pool
cat <<EOF | kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool-10-0-1-0-24
  namespace: metallb-system
spec:
  addresses:
  - 10.0.1.0/24
---
EOF

# Create MetalLB Advertisement
cat <<EOF | kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-l2-advertisement
  namespace: metallb-system
---
EOF
