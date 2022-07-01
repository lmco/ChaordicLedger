#!/bin/sh

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing graph processor functions."
fi

GRAPH_TMP_DIR=${TEMP_DIR}/graph
mkdir -p ${GRAPH_TMP_DIR}

function init_graphprocessor_deployment()
{
  local graphProcessorDeploymentConfig=$GRAPH_TMP_DIR/init_graphprocessor_deployment.yaml

  export GRAPH_PROCESSOR_IMAGE=${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphprocessor:0.0.1
  populateTemplate ../config/graphprocessor_deployment_template.yaml ${graphProcessorDeploymentConfig}

  kubectl delete -f $graphProcessorDeploymentConfig -n ${NETWORK_NAME} || true
  kubectl create -f $graphProcessorDeploymentConfig -n ${NETWORK_NAME}
}
