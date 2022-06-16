#/bin/sh
. env.sh

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

# Terminate kubectl proxy.
ps -ef | grep "kubectl proxy" | grep -v grep | awk '{print $2;}' | xargs kill -9

# Terminate nodejs Swagger UI.
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
kubectl apply -f metrics/component.yaml &&
kubectl apply -f dashboards/kubernetes/recommended.yaml &&
kubectl proxy &

kubectl create serviceaccount dashboard-admin-sa &&
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa &&
clear

./network msp 3 3 2 && # msp OrgCount OrdererCount PeerCount
./network channel 2 &&
./network peer &&
./network ipfs &&
./network graphinit &&
./network chaincode

# Used the following commands to generate the values:
#    head -c 1KiB /dev/urandom > randomArtifact0.bin
#    sha512sum randomfile1.txt
#    uuidgen
# 
#    tr -dc '[:alnum:] \n' < /dev/urandom | head -c 394 > randomArtifact1.txt
#
# Used the following to get the base64 string for content;
#    cat randomArtifact0.bin | base64 -w 0 

./network query ${ARTIFACT_METADATA_CCNAME} '{"Args":["GetAllMetadata"]}'

LfileArray=("randomArtifact0.bin" "randomArtifact1.txt")
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for item in ${LfileArray[*]}; do
  echo "Adding $item to the ledger."
  itemhash=$(sha512sum ${item} | awk '{print $1;}')
  itemsize=$(du -b ${item} | awk '{print $1;}')
  itemcontent=$(cat ${item} | base64 -w 0)
  ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["CreateMetadata","'${timestamp}'","'${itemhash}'","SHA512","'${item}'","'${itemsize}'"]}'
  ./network invoke ${ARTIFACT_CONTENT_CCNAME} '{"Args":["CreateContent","'${timestamp}'","'${item}'","'${itemcontent}'"]}'
  ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["MetadataExists","'${item}'"]}'
  ./network invoke ${ARTIFACT_CONTENT_CCNAME} '{"Args":["ContentExists","'${item}'"]}'
done

./network query ${ARTIFACT_METADATA_CCNAME} '{"Args":["GetAllMetadata"]}'
./network query ${ARTIFACT_CONTENT_CCNAME} '{"Args":["GetAllContent"]}'

# Note: This assumes api/server/out/nodejs was pulled local.

# Pull the latest nodejs-server.zip artifact from the latest successful GitHub run.
#   Ideally, this would be in an NPM registry, but an account doesn't yet exist for the lmco organization.
#   TODO: Once the org exists, look into NPM packaging at https://docs.github.com/en/actions/publishing-packages/publishing-nodejs-packages
. githubReadToken.sh
latestSuccessfulRun=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/lmco/chaordicledger/actions/runs?state=Success | jq '.workflow_runs[0].id')
zipDownloadUrl=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/lmco/chaordicledger/actions/runs/${latestSuccessfulRun}/artifacts | jq '.artifacts[] | select(.name=="nodejs-server")' | jq '.archive_download_url' | tr -d '\"')
curl -vvv -L -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${githubReadToken}" ${zipDownloadUrl} --output nodejs-server.zip
rm -rf apiServer
unzip nodejs-server.zip -d apiServer

pushd apiServer
nohup npm start &
popd

sleep 10

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
