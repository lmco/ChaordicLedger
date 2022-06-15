#!/bin/sh

GRAPH_TMP_DIR=${TEMP_DIR}/graph
mkdir -p ${GRAPH_TMP_DIR}

function init_graphprocessor_job()
{
  local graphJobConfig=$GRAPH_TMP_DIR/init_graphprocessor_job_template.yaml

  export GRAPH_PROCESSOR_IMAGE=${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphprocessor:0.0.1
  populateTemplate ../config/graphprocessor_job_template.yaml ${graphJobConfig}

  kubectl delete -f $graphJobConfig -n ${NETWORK_NAME} || true
  kubectl delete secret processor-args -n ${NETWORK_NAME} || true
  
  kubectl create secret generic processor-args --from-literal=arg1="" --from-literal=arg2="" --from-literal=arg3="/dns/ipfs-ui/tcp/5001/http" --from-literal=arg4="init" --from-literal=arg5='{}' --from-literal=arg6="{}" -n ${NETWORK_NAME}
  kubectl create -f $graphJobConfig -n ${NETWORK_NAME}
}

function modify_graphprocessor_job()
{
  local graphJobConfig=$GRAPH_TMP_DIR/modify_graphprocessor_job_template.yaml

  export GRAPH_PROCESSOR_IMAGE=${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphprocessor:0.0.1
  populateTemplate ../config/graphprocessor_job_template.yaml ${graphJobConfig}

  kubectl delete -f $graphJobConfig -n ${NETWORK_NAME} || true
  kubectl delete secret processor-args -n ${NETWORK_NAME} || true
  
  kubectl create secret generic processor-args --from-literal=arg1="" --from-literal=arg2="" --from-literal=arg3="/dns/ipfs-ui/tcp/5001/http" --from-literal=arg4="write" --from-literal=arg5='{"nodeid":"A","fileid":"something"}' --from-literal=arg6="{}" -n ${NETWORK_NAME}
  kubectl create -f $graphJobConfig -n ${NETWORK_NAME}
}
