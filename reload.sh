#/bin/sh
set -e

function log() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now] $1"
}

function terminateProcess() {
  expr=$1
  result=$(ps -ef | grep "$expr" | grep -v grep | awk '{print $2;}')

  if [ -z "$result" ]; then
    echo "No need to terminate \"$expr\"; it's not running."
  else
    kill -9 $result
  fi
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

if [ -f kubectl_proxy.log ]; then
  rm kubectl_proxy.log
fi

# Terminate kubectl port-forwarding for monitoring.
terminateProcess "kubectl port-forward"

# Terminate kubectl proxy.
terminateProcess "kubectl proxy"

# Terminate nodejs Swagger UI.
terminateProcess "node index"

if [ -d "apiServer" ]; then
  rm -rf apiServer
fi

export ADDITIONAL_CA_CERTS_LOCATION=/home/cloud-user/cachain/
export TEST_NETWORK_ADDITIONAL_CA_TRUST=${ADDITIONAL_CA_CERTS_LOCATION}
cd ~/git/ChaordicLedger/

./network purge &&
./network init &&
./network monitor &&
./network msp 3 3 2 && # msp OrgCount OrdererCount PeerCount
./network channel 2 &&
./network peer &&
./network ipfs &&
./network graphinit &&
./network graphprocessor &&
./network chaincode

./network query ${ARTIFACT_METADATA_CCNAME} '{"Args":["GetAllMetadata"]}'

LfileArray=("randomArtifact0.bin" "randomArtifact1.txt")
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for item in ${LfileArray[*]}; do
  log "Adding $item to the ledger."
  itemhash=$(sha512sum ${item} | awk '{print $1;}')
  itemsize=$(du -b ${item} | awk '{print $1;}')
  itemcontent=$(cat ${item} | base64 -w 0)
  ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["CreateMetadata","'${timestamp}'","'${itemhash}'","SHA512","'${item}'","'${itemsize}'"]}'
  ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["MetadataExists","'${item}'"]}'
done

./network query ${ARTIFACT_METADATA_CCNAME} '{"Args":["GetAllMetadata"]}'

./network query ${ARTIFACT_CONTENT_CCNAME} '{"Args":["GetAllContent"]}'

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

log "Creating service account for dashboard"
kubectl create serviceaccount dashboard-admin-sa &&
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa &&
kubectl apply -f metrics/components.yaml &&
kubectl rollout status deployment metrics-server -n kube-system --timeout=120s &&
kubectl apply -f dashboards/kubernetes/recommended.yaml &&
kubectl rollout status deployment kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

nohup kubectl proxy > kubectl_proxy.log 2>&1 &

# Get current graph state
currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $currentGraphState | jq

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

log "View the API documentation at http://localhost:8080/docs"
log "View the Elastic dashboard at http://localhost:5601/"
log "View the ChaordicLedger metrics at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/pod?namespace=chaordicledger"
log "Note: Reveal the Kubernetes Dashboard login token with ./revealLoginToken.sh"

log "Done"
