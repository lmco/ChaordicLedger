#!/bin/sh
set -x
export CORE_PEER_ADDRESS=org1-peer1:7051
peer chaincode query -n ${CHAINCODE_NAME} -C ${CHANNEL_NAME} -c '$parameters'
