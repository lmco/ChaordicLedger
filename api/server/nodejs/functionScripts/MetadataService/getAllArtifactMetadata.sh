#!/bin/sh
set -x
start=$SECONDS

export CORE_PEER_ADDRESS=org1-peer1:7051

result=$(peer chaincode query -n artifact-metadata -C cl -c '{"Args":["GetAllMetadata"]}')

if [ "$result" == "" ]
then
      result="\"\""
fi

duration=$(( SECONDS - start ))

echo "{ \"durationInSeconds\": \"$duration\", \"result\": $result }"
