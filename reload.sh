#/bin/sh

rm api/builder/cachain/*.cer
rm api/server/cachain/*.cer
rm chaincode/artifact-metadata/docker/cachain/*.cer
rm hyperledger/admin-cli/cachain/*.cer
rm test/cachain/*.cer

unzip -o cachain.zip
mkdir -p api/builder/cachain/
mkdir -p api/server/cachain/
mkdir -p chaincode/artifact-metadata/docker/cachain/
mkdir -p hyperledger/admin-cli/cachain/
mkdir -p test/cachain/

cp LMChain/* api/builder/cachain/
cp LMChain/* api/server/cachain/
cp LMChain/* chaincode/artifact-metadata/docker/cachain/
cp LMChain/* hyperledger/admin-cli/cachain/
cp LMChain/* test/cachain/

rm -rf LMChain

# Note: This assumes nodejs-server.zip has already been downloaded.
# Termintate nodejs Swagger UI.
ps -ef | grep "node index" | grep -v grep | awk '{print $2;}' | xargs kill -9
rm -rf apiServer
mkdir apiServer
unzip nodejs-server.zip -d ./apiServer

export ADDITIONAL_CA_CERTS_LOCATION=/home/cloud-user/cachain/
export TEST_NETWORK_ADDITIONAL_CA_TRUST=${ADDITIONAL_CA_CERTS_LOCATION}
cd ~/git/ChaordicLedger/

clear &&
./network purge &&
./network init &&
clear &&
./network msp 3 3 2 && # msp OrgCount OrdererCount PeerCount
./network channel 2 &&
./network peer #&&
#./network chaincode
exit 0
#exit 1
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


# Note: This assumes api/server/out/nodejs was pulled local.
# TODO: Look into NPM packaging at https://docs.github.com/en/actions/publishing-packages/publishing-nodejs-packages
pushd apiServer
nohup npm start &
popd

# timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# for item in ${LfileArray[*]}; do
#   echo "Adding $item to the ledger."
#   itemhash=$(sha256sum ${item} | awk '{print $1;}')
#   itemsize=$(du -b ${item} | awk '{print $1;}')
#   ./network invoke '{"Args":["UpdateMetadata","'${timestamp}'","'${itemhash}'","SHA256","'${item}'","'${itemsize}'"]}'
# done

# ./network query '{"Args":["GetAllMetadata"]}'

# for item in ${LfileArray[*]}; do
#   ./network invoke '{"Args":["DeleteMetadata","'${item}'"]}'
#   ./network query '{"Args":["GetAllMetadata"]}'
# done

./network ipfs

# Get default file.
defaultFile=$(curl -X GET "http://localhost:8080/v1/artifacts?path=%2Ftmp" -H "accept: */*" | jq .result | sed "s|[\"]||g" | sed "s|\\\\n||g")
echo $defaultFile

# Get default file contents.
curl -X GET "http://localhost:8080/v1/artifact?artifactPath=%2Ftmp%2F$defaultFile" -H "accept: */*" | jq .result | sed "s|[\"]||g" | sed "s|\\\\n||g"

# Create new file via API.
curl -X POST "http://localhost:8080/v1/artifact?artifactPath=%2Fsome%2Fother%2Fpath.txt" -H "accept: */*"

# List files at new path.
fileName=$(curl -X GET "http://localhost:8080/v1/artifacts?path=%2Fsome%2Fother" -H "accept: */*" | jq .result | sed "s|[\"]||g" | sed "s|\\\\n||g")
echo $fileName

# Get file contents.
curl -X GET "http://localhost:8080/v1/artifact?artifactPath=%2Fsome%2Fother%2F$fileName" -H "accept: */*" | jq .result | sed "s|[\"]||g" | sed "s|\\\\n||g"
