#!/bin/sh
set -x
# This runs on the org admin image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

export CORE_PEER_ADDRESS=org1-peer1:7051

result=$(peer chaincode query -n artifact-metadata -C cl -c '{"Args":["GetAllMetadata"]}')

if [ "$result" == "" ]
then
  result="\"\""
fi

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

echo "{ \"durationInMicroseconds\": \"$duration\", \"result\": $result }"
