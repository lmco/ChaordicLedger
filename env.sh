#!/bin/sh

export SYSTEM_NAME="chaordicledger"

function syslog() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now | ${SYSTEM_NAME} | INFO] $1"
}

function syserr() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now | ${SYSTEM_NAME} | ERROR] $1"
}

function sourceProxyDetails() {
  proxy_details_source_file=docker_registry_proxy_details.sh
  if [[ -f "$proxy_details_source_file" ]]; then
    syslog "Sourcing proxy details from $proxy_details_source_file"
    . ./$proxy_details_source_file

    if [[ "$REGISTRY_LOGIN_REQUIRED" == "true" ]]; then
      syslog "Logging in to $DOCKER_REGISTRY_PROXY"
      #syslog "echoing \$REGISTRY_TOKEN into \"docker login $DOCKER_REGISTRY_PROXY -u $REGISTRY_USER --password-stdin\""
      echo $REGISTRY_TOKEN | docker login $DOCKER_REGISTRY_PROXY -u $REGISTRY_USER --password-stdin
    fi
  else
    syslog "No proxy details file to source."
  fi
}

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing environment file."
fi

sourceProxyDetails

export FABRIC_CA_VERSION=1.5.3
export FABRIC_VERSION=2.4.3
export FABRIC_CONTAINER_REGISTRY="${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}hyperledger"

export ARTIFACT_METADATA_CCNAME="artifact-metadata"
export ARTIFACT_CONTENT_CCNAME="artifact-content"
export ARTIFACT_RELATIONSHIP_CCNAME="artifact-relationship"
export LIGHTSWITCH_CCNAME="lightswitch"
