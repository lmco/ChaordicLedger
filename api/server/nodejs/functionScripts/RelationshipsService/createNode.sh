#!/bin/sh
set -x
export CORE_PEER_ADDRESS=org1-peer1:7051

friendlyName=$(date -u +%Y%m%dT%H%M%SZ)

filename=${friendlyName}_node.json
echo '{{body}}' | sed 's:^.\(.*\).$:\1:' > $filename

nodeid=$(cat $filename | jq .nodeida | tr -d '"')
fileid=$(cat $filename | jq .nodeidb | tr -d '"')

peer chaincode \
      invoke \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
      -n artifact-relationship \
      -C cl \
      -c "{\"Args\":[\"CreateNode\",\"${nodeid}\",\"${fileid}\"]}"
