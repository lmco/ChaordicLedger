#!/bin/sh
set -x

blockFileName="{{CHANNEL_NAME}}_{{blocknumber}}.block"

peer channel fetch {{blocknumber}} -o org0-orderer1:6050 --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem -c {{CHANNEL_NAME}}
configtxlator proto_decode --type common.Block --input $blockFileName | tr -d "\t\n"
rm $blockFileName
