#!/bin/sh
set -x
# This runs on the org admin image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
defaultFileName=$(echo $now | sed "s|[:-]||g")
defaultFilePath=/tmp/$defaultFileName.txt
#echo "The quick brown fox jumps over the lazy dog." > $defaultFilePath
#ipfs add $defaultFilePath -Q
result=$(echo "$now The quick brown fox jumps over the lazy dog." | ipfs files write --create --parents $defaultFilePath)
echo $defaultFilePath

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

echo "{ \"file\" : \"$defaultFileName\", \"durationInMicroseconds\": \"$duration\", \"result\": \"$result\" }"
