#!/bin/sh
set -x
export CORE_PEER_ADDRESS=org1-peer1:7051

#uuid=`uuidgen`
item="something.bin"
head -c 1KiB /dev/urandom >${item}

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
itemhash=$(sha512sum ${item} | awk '{print $1;}')
itemsize=$(du -b ${item} | awk '{print $1;}')

peer chaincode \
        invoke \
        -o org0-orderer1:6050 \
        --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
        -n artifact-metadata \
        -C cl \
        -c '{"Args":["CreateMetadata","'${timestamp}'","'${itemhash}'","SHA512","'${item}'","'${itemsize}'"]}'

rm ${item}
