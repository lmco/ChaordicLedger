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
payload=$(cat $resultfile | grep chaincodeInvokeOrQuery | sed "s|.*payload:||g" | base64 -w 0)

# Note: The payload is a protobuf-encoded peer.ProcessedTransaction.
#       Unfortunately, using "configtxlator proto_decode --type peer.ProcessedTransaction" on a file with
#       the encoded contents fails with "configtxlator: error: Error decoding: message of type %!s(<nil>) unknown".
#
#       The protobuf format also contains incompatible escape characters for JSON payloads, so
#       this is being returned as a base64-encoded string.

if [ "$payload" == "" ]
then
  payload="\"\""
fi

#end=$(date +%s%N)
# end=${EPOCHREALTIME/./}
# duration=$(( end - start ))

echo "{ \"transaction\" : \"$friendlyName\", \"result\": \"$payload\" }"
