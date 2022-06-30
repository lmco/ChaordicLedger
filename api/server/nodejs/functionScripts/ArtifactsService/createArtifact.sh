#!/bin/sh
set -x
start=$(date +%s%N)

export CORE_PEER_ADDRESS=org1-peer1:7051

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

filename=${friendlyName}_artifact.json
echo '{{formData}}' | sed 's:^.\(.*\).$:\1:' > $filename

friendlyName=$(cat $filename | jq .originalname | tr -d '"')

content=$(cat $filename | sed 's|"|\\"|g')

result=$(peer chaincode \
      query \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
      -n artifact-content \
      -C cl \
      -c "{\"Args\":[\"CreateContent\",\"${timestamp}\",\"${friendlyName}\",\"${content}\"]}" )

if [ "$result" == "" ]
then
      result="\"\""
fi

end=$(date +%s%N)
duration=$(( end - start ))

echo "{ \"file\" : \"$friendlyName\", \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
