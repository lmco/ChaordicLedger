#!/bin/sh
set -x
export CORE_PEER_ADDRESS=org1-peer1:7051

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

friendlytimestamp=$(date -u +%Y%m%d%H%M%S)

filename=${friendlytimestamp}_txquery.json

TX_ID="{{transactionID}}"

content=$(cat $filename | sed 's|"|\\"|g')

# Note: The response from a peer invocation comes back on stderr, not stdout.
#       The workaround is to redirect to a file and cat the contents.
resultfile="${friendlytimestamp}_${TX_ID}_result.txt"
peer chaincode \
      invoke \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
      -n qscc \
      -C cl \
      -c "{\"function\":\"GetTransactionByID\",\"Args\":[\"cl\", \"${TX_ID}\"]}" > $resultfile 2>&1

status=$(cat $resultfile | grep chaincodeInvokeOrQuery | sed "s|.*result: ||g" | cut -d " " -f 1)
payload=$(cat $resultfile | grep chaincodeInvokeOrQuery | sed "s|.*result: ||g" | cut -d " " -f 2 | sed "s|payload:||g" | cut -c2- | rev | cut -c2- | rev | tr -d "\\")

if [ "$payload" == "" ]
then
  payload="{}"
fi

#end=$(date +%s%N)
# end=${EPOCHREALTIME/./}
# duration=$(( end - start ))

echo "{ \"transaction\" : \"$friendlyName\", \"result\": $payload }"
