#!/bin/sh

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing diagnostic functions."
fi

CURL_TMP_DIR=${TEMP_DIR}/curl
mkdir -p ${CURL_TMP_DIR}

function run_curl()
{
  local curlJobConfig=$CURL_TMP_DIR/run_curl_job_template.yaml

  export CURL_URL=$1
  export CURL_IMAGE=${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}curlimages/curl:7.83.1
  
  populateTemplate ../config/curl_job_template.yaml ${curlJobConfig}

  kubectl delete -f $curlJobConfig -n ${NETWORK_NAME} || true
  kubectl create -f $curlJobConfig -n ${NETWORK_NAME}
  kubectl wait --for=condition=complete --timeout=30s job/run-curl -n ${NETWORK_NAME}
  kubectl get pods --selector=job-name=run-curl -n ${NETWORK_NAME} -o json | jq .items[0].metadata.name | tr -d '"' | xargs kubectl logs -n ${NETWORK_NAME}
}
