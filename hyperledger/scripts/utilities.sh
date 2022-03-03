#!/bin/sh

# Performs substitutions in a template based on known global variables.
function populateTemplate() {
  local templateFile=$1
  local outputPath=$2

  echo "Processing template \"${templateFile}\" to create \"${outputPath}\""

  # TODO: loop through env and substitute known variables.

  cat ${templateFile} | 
    sed "s|{{ingress_http_port}}|${NGINX_HTTP_PORT}|g" |
    sed "s|{{ingress_https_port}}|${NGINX_HTTPS_PORT}|g" |
    sed "s|{{reg_name}}|${LOCAL_REGISTRY_NAME}|g" |
    sed "s|{{reg_port}}|${LOCAL_REGISTRY_PORT}|g" |
    sed "s|{{CHAINCODE_NAME}}|${CHAINCODE_NAME}|g" |
    sed "s|{{CHAINCODE_ID}}|${CHAINCODE_ID}|g" |
    sed "s|{{CHAINCODE_IMAGE}}|${CHAINCODE_IMAGE}|g" |
    sed "s|{{PEER_NAME}}|${PEER_NAME}|g" > ${outputPath}

  populatedTemplate=${outputPath}
}

function applyPopulatedTemplate() {
  local templateFile=$1
  local outputPath=$2
  local ns=$3

  populateTemplate $templateFile $outputPath

  if [ "${ns}" == "" ]; then
    kubectl apply -f ${populatedTemplate}
  else
    kubectl -n ${ns} apply -f ${populatedTemplate}
  fi

  unset populatedTemplate
}
