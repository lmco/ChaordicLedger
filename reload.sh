#!/bin/bash
set -e
start=$SECONDS

BASEDIR=$(dirname "$0")

function log() {
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "[$now] $1"
}

function terminateProcess() {
        expr=$1
        result=$(ps -ef | grep "$expr" | grep -v grep | awk '{print $2;}')

        if [ -z "$result" ]; then
                syslog "No need to terminate \"$expr\"; it's not running."
        else
                syslog "Terminating process matching \"$expr\" that has PID $result."
                kill -9 $result
        fi
}

function removeCertsIfExist() {
        result=$(find $1 -type f -name \*.cer | wc -l)
        if [ $result -gt 0 ]; then
                rm $1/*.cer
        else
                echo "NOT removing certificate files from $1; no certificate files exist in that directory."
        fi
}

ls -rotl

. ./env.sh

syslog "Starting reload."

syslog "Removing corporate Certificate Authority certificates."
removeCertsIfExist api/builder/cachain
removeCertsIfExist api/server/cachain
removeCertsIfExist chaincode/artifact-metadata/docker/cachain
removeCertsIfExist hyperledger/admin-cli/cachain
removeCertsIfExist test/cachain/cachain

syslog "Expanding archive of corporate Certificate Authority certificates."
unzip -o cachain.zip
mkdir -p api/builder/cachain/
mkdir -p api/server/cachain/
mkdir -p chaincode/artifact-metadata/docker/cachain/
mkdir -p hyperledger/admin-cli/cachain/
mkdir -p test/cachain/

syslog "Loading corporate Certificate Authority certificates where necessary."
pushd LMChain
for file in *.cer; do
        mv -- "$file" "${file%.cer}.crt"
done
popd

cp LMChain/* api/builder/cachain/
cp LMChain/* api/server/cachain/
cp LMChain/* chaincode/artifact-metadata/docker/cachain/
cp LMChain/* hyperledger/admin-cli/cachain/
cp LMChain/* test/cachain/

syslog "Removing Certificate Authority certificate extraction directory."
rm -rf LMChain

if [ -f kubectl_proxy.log ]; then
        syslog "Removing kubectl proxy log."
        rm kubectl_proxy.log
fi

syslog "Terminating kubectl port-forwarding for monitoring."
terminateProcess "kubectl port-forward"

syslog "Terminaging kubectl proxy."
terminateProcess "kubectl proxy"

syslog "Terminaging nodejs Swagger UI."
terminateProcess "node index"

if [ -d "apiServer" ]; then
        syslog "Removing API server directory."
        rm -rf apiServer
else
        syslog "NOT removing API server directory. It does not exist."
fi

if [ -f nodejs-server.zip ]; then
        syslog "Removing nodejs server archive."
        rm nodejs-server.zip
fi

export ADDITIONAL_CA_CERTS_LOCATION="${PWD}/test/cachain/"
export TEST_NETWORK_ADDITIONAL_CA_TRUST=${ADDITIONAL_CA_CERTS_LOCATION}
cd $BASEDIR

syslog "Initializing the system."
pwd
ls -l
./network purge &&
        ./network init &&
        ./network msp 2 1 1 && # msp OrgCount OrdererCount PeerCount
        ./network channel 2 && # channel OrgCount
        ./network peer 1 1 &&  # peer OrdererCount PeerCount
        ./network ipfs &&
        ./network graphinit &&
        ./network graphprocessor &&
        ./network chaincode 1 1 # chaincode OrgCount PeerCount

syslog "Invoking metadata chaincode."
./network query ${ARTIFACT_METADATA_CCNAME} '{"Args":["GetAllMetadata"]}'

LfileArray=("randomArtifact0.bin" "randomArtifact1.txt")
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for item in ${LfileArray[*]}; do
        syslog "Adding metadata for artifact \"$item\" to the ledger."
        itemhash=$(sha512sum ${item} | awk '{print $1;}')
        itemsize=$(du -b ${item} | awk '{print $1;}')
        itemcontent=$(cat ${item} | base64 -w 0)

        ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["CreateMetadata","'${timestamp}'","'${itemhash}'","SHA512","'${item}'","'${itemsize}'"]}'
        ./network invoke ${ARTIFACT_METADATA_CCNAME} '{"Args":["MetadataExists","'${item}'"]}'
done

syslog "Querying metadata chaincode."
./network query ${ARTIFACT_METADATA_CCNAME} '{"Args":["GetAllMetadata"]}'
./network query ${ARTIFACT_CONTENT_CCNAME} '{"Args":["GetAllContent"]}'

# Setup local routing so API can reach the pods
controlPlaneIP=$(docker container inspect chaordiccluster-control-plane --format '{{ .NetworkSettings.Networks.kind.IPAddress }}')
ipfsPodName=$(kubectl -n chaordicledger get pods | grep "ipfs-" | awk '{print $1;}')
ipfsPodIp=$(kubectl -n chaordicledger get pod $ipfsPodName -o json | jq -r '.status.podIP')
sudo ip route add $ipfsPodIp via $controlPlaneIP || true

ip route

syslog "Pull the latest nodejs-server.zip artifact from the latest successful GitHub run."

#   Note: Ideally, this would be in an NPM registry, but an account doesn't yet exist for the lmco organization.
#   TODO: Once the org exists, look into NPM packaging at https://docs.github.com/en/actions/publishing-packages/publishing-nodejs-packages
. githubReadToken.sh
latestSuccessfulRun=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/lmco/chaordicledger/actions/runs?state=Success | jq '.workflow_runs[0].id')
zipDownloadUrl=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/lmco/chaordicledger/actions/runs/${latestSuccessfulRun}/artifacts | jq '.artifacts[] | select(.name=="nodejs-server")' | jq '.archive_download_url' | tr -d '\"')
curl -vvv -L -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${githubReadToken}" ${zipDownloadUrl} --output nodejs-server.zip

syslog "Extracting nodejs-server.zip artifact."
unzip nodejs-server.zip -d apiServer

pushd apiServer
syslog "Starting API server."
npm install connect
nohup npm start >apiserver.log 2>&1 &
popd

syslog "Waiting for the API server to start."
sleep 10

if [ "$CL_MONITOR" == "true" ]; then
        ./network monitor

        syslog "Deploying dashboard"
        kubectl apply -f dashboards/kubernetes/recommended.yaml
        kubectl apply -f metrics/components.yaml
        kubectl rollout status deployment metrics-server -n kube-system --timeout=3600s &&
                syslog "Creating service account for dashboard"
        kubectl apply -f dashboards/kubernetes/dashboard-adminuser.yaml

        # TODO: This may not be necessary.
        #syslog "Creating access token for service account"
        #kubectl -n kubernetes-dashboard create token admin-user

        kubectl create serviceaccount dashboard-admin-sa
        kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
        kubectl create token dashboard-admin-sa

        # kubectl apply -f dashboards/kubernetes/recommended.yaml --enable-skip-login &&
        # kubectl rollout status deployment kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

        syslog "Starting kubectl proxy."
        nohup kubectl proxy >kubectl_proxy.log 2>&1 &

        rm -rf kube-state-metrics
        git clone https://github.com/kubernetes/kube-state-metrics.git
        cd kube-state-metrics
        kubectl apply -f examples/standard
        #Or?: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

syslog "Getting the current graph state."
currentGraphState=$(curl -s -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships/getRelationshipGraphFile')
syslog "$(echo $currentGraphState | tr -d '[:space:]')"

syslog "Getting a list of all known artifacts."
allArtifacts=$(curl -s -X GET "http://localhost:8080/v1/artifacts/listAllArtifacts" -H "accept: */*")
syslog "$(echo $allArtifacts | jq .result | tr -d '[:space:]')"

if [ "$allArtifacts" == "" ]; then
        syserr "No response from system."
else
        result=$(echo $allArtifacts | jq .result)

        if [ "$result" == '""' ]; then
                syslog "No known artifacts."
        else
                ipfsNames=$(echo $result | jq .[].IPFSName | sed "s|\"||g")

                for name in $ipfsNames; do
                        syslog "Getting contents of known artifact with name \"$name\""
                        fileData=$(curl -X GET --header 'Accept: application/json' "http://localhost:8080/v1/artifacts/getArtifactObject?artifactID=${name}" | jq .result | sed "s|\\\\n||g")
                        syslog $fileData
                done
        fi
fi

duration=$((SECONDS - start))

syslog "View the API documentation at http://localhost:8080/docs"
syslog "View the Elastic dashboard at http://localhost:5601/"
syslog "View the Elastic Metrics Inventory at http://localhost:5601/app/metrics/inventory and select the metricbeat item"
syslog "View the Elastic Metrics Explorer at http://localhost:5601/app/metrics/explorer?metricsExplorer"
syslog "View the ChaordicLedger metrics at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/pod?namespace=chaordicledger"
syslog "Done initializing the system in $duration seconds."
