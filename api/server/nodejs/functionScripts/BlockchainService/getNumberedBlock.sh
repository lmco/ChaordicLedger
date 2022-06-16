#!/bin/sh
set -x

channel="cl"
blockFileName="${channel}_{{blocknumber}}.block"

peer channel fetch {{blocknumber}} -o org0-orderer1:6050 --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem -c $channel
configtxlator proto_decode --type common.Block --input $blockFileName | tr -d "\t\n"
#rm $blockFileName
