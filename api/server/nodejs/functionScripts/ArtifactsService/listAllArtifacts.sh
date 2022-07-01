#!/bin/sh
set -x
# This runs on the org admin image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

export CORE_PEER_ADDRESS=org1-peer1:7051

result=$(peer chaincode \
      query \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
      -n artifact-content \
      -C cl \
      -c "{\"Args\":[\"GetAllContent\"]}" | tr -d "\n")

if [ "$result" == "" ]
then
  result="\"\""
fi

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

echo "{ \"durationInMicroseconds\": \"$duration\", \"result\": $result }"
