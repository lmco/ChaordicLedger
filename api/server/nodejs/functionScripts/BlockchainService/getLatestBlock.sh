#!/bin/sh
set -x

peer channel fetch newest -o org0-orderer1:6050 --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem -c cl
configtxlator proto_decode --type common.Block --input cl_newest.block | tr -d "\t\n"
