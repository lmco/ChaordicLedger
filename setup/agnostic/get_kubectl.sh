#!/bin/sh

curl -LO "https://dl.k8s.io/release/v1.23.3/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/v1.23.3/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256)  kubectl" | sha256sum --check
rm kubectl.sha256
chmod +x kubectl
mv ./kubectl ~/.local/bin/
kubectl version --client
