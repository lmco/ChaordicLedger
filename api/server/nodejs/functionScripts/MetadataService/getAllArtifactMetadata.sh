#!/bin/sh
set -x
start=$(date +%s%N)

export CORE_PEER_ADDRESS=org1-peer1:7051

result=$(peer chaincode query -n artifact-metadata -C cl -c '{"Args":["GetAllMetadata"]}')

if [ "$result" == "" ]
then
      result="\"\""
fi

end=$(date +%s%N)
duration=$(( end - start ))

echo "{ \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
