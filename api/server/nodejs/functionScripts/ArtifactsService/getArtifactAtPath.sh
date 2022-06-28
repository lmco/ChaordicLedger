#!/bin/sh
set -x
path="{{artifactPath}}"

# The base64 command lacks the columns (-w) switch, so remove newlines manually.
content=$(ipfs files read $path | base64 | tr -d "\n")

echo "{ \"path\" : \"$path\", \"content\": \"$content\"}"
