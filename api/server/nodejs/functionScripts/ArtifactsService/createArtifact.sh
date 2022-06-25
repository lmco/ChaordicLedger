#!/bin/sh
set -x
export CORE_PEER_ADDRESS=org1-peer1:7051

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# TODO: Update the interface to allow the user to provide a friendly name.
friendlyName=$(date -u +%Y%m%dT%H%M%SZ)

filename=${friendlyName}_artifact.json
echo '{{formData}}' | sed 's:^.\(.*\).$:\1:' > $filename

content=$(cat $filename | sed 's|"|\\"|g')

peer chaincode \
      invoke \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
      -n artifact-content \
      -C cl \
      -c "{\"Args\":[\"CreateContent\",\"${timestamp}\",\"${friendlyName}\",\"${content}\"]}"



# now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

# data="{{body}}"

# echo "$data" > /tmp/data.json

# ipfs object put /tmp/data.json
# #echo "$now The quick brown fox jumps over the lazy dog." | ipfs files write --create --parents {{artifactPath}}
