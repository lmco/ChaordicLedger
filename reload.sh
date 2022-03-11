#/bin/sh

rm -rf /tmp/chaordicledger

export ADDITIONAL_CA_CERTS_LOCATION=/home/cloud-user/cachain/
export TEST_NETWORK_ADDITIONAL_CA_TRUST=${ADDITIONAL_CA_CERTS_LOCATION}
cd ~/git/ChaordicLedger/

clear &&
./network purge &&
./network init &&
clear &&
./network msp 3 3 2 && # msp OrgCount OrdererCount PeerCount
./network channel 2 &&
./network peer &&
./network chaincode

# Used the following commands to generate the values:
#    head -c 1KiB /dev/urandom > randomArtifact0.bin
#    sha512sum randomfile1.txt
#    uuidgen
# 
#    tr -dc '[:alnum:] \n' < /dev/urandom | head -c 394 > randomArtifact1.txt

./network query '{"Args":["GetAllMetadata"]}'

LfileArray=("randomArtifact0.bin" "randomArtifact1.txt")
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for item in ${LfileArray[*]}; do
  echo "Adding $item to the ledger."
  itemhash=$(sha512sum ${item} | awk '{print $1;}')
  itemsize=$(du -b ${item} | awk '{print $1;}')
  ./network invoke '{"Args":["CreateMetadata","'${timestamp}'","'${itemhash}'","SHA512","'${item}'","'${itemsize}'"]}'
  ./network invoke '{"Args":["MetadataExists","'${item}'"]}'
done

./network query '{"Args":["GetAllMetadata"]}'

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for item in ${LfileArray[*]}; do
  echo "Adding $item to the ledger."
  itemhash=$(sha256sum ${item} | awk '{print $1;}')
  itemsize=$(du -b ${item} | awk '{print $1;}')
  ./network invoke '{"Args":["UpdateMetadata","'${timestamp}'","'${itemhash}'","SHA256","'${item}'","'${itemsize}'"]}'
done

./network query '{"Args":["GetAllMetadata"]}'

for item in ${LfileArray[*]}; do
  ./network invoke '{"Args":["DeleteMetadata","'${item}'"]}'
  ./network query '{"Args":["GetAllMetadata"]}'
done
