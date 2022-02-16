#!/bin/sh

curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64"
chmod +x ./kind
mv ./kind ~/.local/bin/
kind --version
