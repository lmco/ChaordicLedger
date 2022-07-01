#!/bin/sh
set -x
# This runs on the IPFS image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

path="{{artifactPath}}"
# The base64 command lacks the columns (-w) switch, so remove newlines manually.
content=$(ipfs files read $path | base64 | tr -d "\n")

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))
#echo "{ \"path\" : \"$path\", \"content\": \"$content\", \"durationInNanoseconds\": \"$duration\"}"
echo "{ \"path\" : \"$path\", \"content\": \"$content\", \"durationInMicroseconds\": \"$duration\"}"
