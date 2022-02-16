#!/bin/sh

curl -LO "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
chmod +x jq-linux64
mkdir -p ~/.local/bin
mv ./jq-linux64 ~/.local/bin/jq
jq --version
