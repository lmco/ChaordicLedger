#/bin/sh
function log() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now] $1"
}

log "Starting reload."

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
rm kubectl_proxy.log

# Terminate kubectl proxy.
ps -ef | grep "kubectl proxy" | grep -v grep | awk '{print $2;}' | xargs kill -9

# Terminate nodejs Swagger UI.
ps -ef | grep "node index" | grep -v grep | awk '{print $2;}' | xargs kill -9

rm -rf apiServer

export ADDITIONAL_CA_CERTS_LOCATION=/home/cloud-user/cachain/
export TEST_NETWORK_ADDITIONAL_CA_TRUST=${ADDITIONAL_CA_CERTS_LOCATION}
cd ~/git/ChaordicLedger/

./network purge &&
./network init &&
./network msp 3 3 2 && # msp OrgCount OrdererCount PeerCount
./network channel 2 &&
./network peer &&
./network ipfs &&
./network graphinit &&
./network graphprocessor &&
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
  log "Adding $item to the ledger."
  itemhash=$(sha512sum ${item} | awk '{print $1;}')
  itemsize=$(du -b ${item} | awk '{print $1;}')
  itemcontent=$(cat ${item} | base64 -w 0)
  ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["CreateMetadata","'${timestamp}'","'${itemhash}'","SHA512","'${item}'","'${itemsize}'"]}'
  #./network invoke ${ARTIFACT_CONTENT_CCNAME} '{"Args":["CreateContent","'${timestamp}'","'${item}'","'${itemcontent}'"]}'
  ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["MetadataExists","'${item}'"]}'
  #./network invoke ${ARTIFACT_CONTENT_CCNAME} '{"Args":["ContentExists","'${item}'"]}'
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
nohup npm start > apiserver.log 2>&1  &
popd

sleep 10

# Get current graph state
currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $currentGraphState | jq

# now=`date -u +"%Y%m%dT%H%M%SZ"`
# randomFile1=randomArtifact_${now}.bin
# head -c 1KiB /dev/urandom > $randomFile1
# curl -X POST -F "upfile=@${randomFile1}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' 'http://localhost:8080/v1/artifact'
# sleep 2

# # Create another random file and upload it.
# now=`date -u +"%Y%m%dT%H%M%SZ"`
# randomFile2=randomArtifact_${now}.bin
# head -c 1KiB /dev/urandom > $randomFile2
# curl -X POST -F "upfile=@${randomFile2}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' 'http://localhost:8080/v1/artifact'

# # Create a relationship between the two files
# curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
#   "nodeida": "'${randomFile1}'",
#   "nodeidb": "'${randomFile2}'"
# }' 'http://localhost:8080/v1/relationships/createRelationship'

# Get all known artifacts.
allArtifacts=$(curl -X GET "http://localhost:8080/v1/artifacts/all" -H "accept: */*" | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $allArtifacts | jq

ipfsNames=$(echo $allArtifacts | jq .[].IPFSName | sed "s|\"||g")
for name in $ipfsNames
do
  #fileData=$(curl -X GET --header 'Accept: application/json' "http://localhost:8080/v1/artifactObject?artifactID=${name}" | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
  fileData=$(curl -X GET --header 'Accept: application/json' "http://localhost:8080/v1/artifactObject?artifactID=${name}" | jq .result | sed "s|\\\\n||g")
  echo $fileData
done

log "Creating service account for dashboard"
kubectl create serviceaccount dashboard-admin-sa &&
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa &&
kubectl apply -f metrics/components.yaml &&
kubectl rollout status deployment metrics-server -n kube-system --timeout=120s &&
kubectl apply -f dashboards/kubernetes/recommended.yaml &&
kubectl rollout status deployment kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

nohup kubectl proxy > kubectl_proxy.log 2>&1 &

log "Done"
