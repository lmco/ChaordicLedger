#!/bin/sh
set -x
start=$(date +%s%N)

path="{{artifactPath}}"
# The base64 command lacks the columns (-w) switch, so remove newlines manually.
content=$(ipfs files read $path | base64 | tr -d "\n")

end=$(date +%s%N)
duration=$(( end - start ))
echo "{ \"path\" : \"$path\", \"content\": \"$content\", \"durationInNanoseconds\": \"$duration\"}"
