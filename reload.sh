#/bin/sh

export ADDITIONAL_CA_CERTS_LOCATION=/home/cloud-user/cachain/
export TEST_NETWORK_ADDITIONAL_CA_TRUST=${ADDITIONAL_CA_CERTS_LOCATION}
cd ~/git/ChaordicLedger/

clear &&
./network purge &&
./network init &&
clear &&
./network msp 1 1 1
