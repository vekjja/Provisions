#!/bin/bash

                                          
# 88888888ba   88                           
# 88      "8b  88                           
# 88      ,8P  88                           
# 88aaaaaa8P'  88   ,adPPYba,  8b,     ,d8  
# 88""""""'    88  a8P_____88   `Y8, ,8P'   
# 88           88  8PP"""""""     )888(     
# 88           88  "8b,   ,aa   ,d8" "8b,   
# 88           88   `"Ybbd8"'  8P'     `Y8  
                                          
                                          

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "ssd-movies"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "ssd-movies"
  capacity:
    storage: "900Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/ssd/movies"
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "ssd-series"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "ssd-series"
  capacity:
    storage: "900Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/ssd/series"
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "ssd-series-ext"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "ssd-series-ext"
  capacity:
    storage: "1000Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/hdd/barracuda/Series"
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "plex-config"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "plex-config"
  capacity:
    storage: "6Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/ssd/pny250/Plex"
EOF

helm upgrade --install plex ./k3s/helm/charts/plex \
  --namespace "plex" \
  --create-namespace \
  --values ./k3s/helm/values/plex.values.yaml
