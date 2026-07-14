#!/bin/bash

                                          
# 88888888ba   88                           
# 88      "8b  88                           
# 88      ,8P  88                           
# 88aaaaaa8P'  88   ,adPPYba,  8b,     ,d8  
# 88""""""'    88  a8P_____88   `Y8, ,8P'   
# 88           88  8PP"""""""     )888(     
# 88           88  "8b,   ,aa   ,d8" "8b,   
# 88           88   `"Ybbd8"'  8P'     `Y8  
                                          
                                          

helm upgrade --install plex ./k3s/helm/charts/plex \
  --namespace "plex" \
  --create-namespace \
  --values ./k3s/helm/values/plex.authriz.io.values.yaml
