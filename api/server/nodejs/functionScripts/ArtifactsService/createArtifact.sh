#!/bin/sh
set -x
export CORE_PEER_ADDRESS=org1-peer1:7051

#uuid=`uuidgen`
# itemid="{{itemid}}"
# content="{{base64encodedContent}}"
# itemsize="{{itemsizeinbytes}}"

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
friendlyName=$(date -u +%Y%m%dT%H%M%SZ)
#itemhash=$(sha512sum ${item} | awk '{print $1;}')
#itemsize=$(du -b ${item} | awk '{print $1;}')

filename=$friendlyName.json
echo '{{formData}}' | sed 's:^.\(.*\).$:\1:' > $filename

content="{{formData}}"

# Hm ... could we make the chaincode read a file?
#data=$(cat $filename)

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
