#!/bin/sh
set -x
# This runs on the org admin image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
# start=${EPOCHREALTIME/./}

export CORE_PEER_ADDRESS=org1-peer1:7051

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

friendlytimestamp=$(date -u +%Y%m%d%H%M%S)

filename={{formData}}
#echo '{{formData}}' | sed 's:^.\(.*\).$:\1:' > $filename

friendlyName=$(cat $filename | jq .originalname | tr -d '"')

content=$(cat $filename | sed 's|"|\\"|g')

# Note: The response from a peer invocation comes back on stderr, not stdout.
#       The workaround is to redirect to a file and cat the contents.
resultfile="${friendlytimestamp}_${friendlyName}_result.txt"
peer chaincode \
      invoke \
      --waitForEvent \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
      -n artifact-content \
      -C cl \
      -c "{\"Args\":[\"CreateContent\",\"${timestamp}\",\"${friendlyName}\",\"${content}\"]}" > $resultfile 2>&1

status=$(cat $resultfile | grep chaincodeInvokeOrQuery | sed "s|.*result: ||g" | cut -d " " -f 1)
payload=$(cat $resultfile | grep chaincodeInvokeOrQuery | sed "s|.*result: ||g" | cut -d " " -f 2 | sed "s|payload:||g" | cut -c2- | rev | cut -c2- | rev | tr -d "\\")

if [ "$payload" == "" ]
then
  payload="{}"
fi

#end=$(date +%s%N)
# end=${EPOCHREALTIME/./}
# duration=$(( end - start ))

# Remove source file
rm $filename

# Remove results file
#rm $resultfile

echo "{ \"operation\" : \"createArtifact\", \"file\" : \"$friendlyName\", \"result\": $payload }"
