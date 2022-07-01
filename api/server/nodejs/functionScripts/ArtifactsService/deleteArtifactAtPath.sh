#!/bin/sh
set -x
# This runs on the IPFS image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

result=$(ipfs files rm {{artifactPath}})

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

echo "{ \"file\" : \"{{artifactPath}}\", \"durationInMicroseconds\": \"$duration\", \"result\": $result }"
