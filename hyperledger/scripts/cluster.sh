#!/bin/sh

set -o errexit

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing hyperledger cluster functions."
fi

CLUSTER_TMP=${TEMP_DIR}/cluster
mkdir -p $CLUSTER_TMP

function cluster_init() {
  cluster_create
  apply_proxy_certs
  apply_nginx_ingress
  install_cert_manager
  launch_docker_registry
  pull_docker_images
  load_docker_images
}

function cluster_create() {
  echo "Creating cluster \"${CLUSTER_NAME}\" with ${NGINX_HTTPS_PORT}"
  populateTemplate ../config/cluster-template.yaml ${CLUSTER_TMP}/${CLUSTER_NAME}_cluster_config.yaml
  kind create cluster --name $CLUSTER_NAME --config=${populatedTemplate}
}

function apply_proxy_certs() {
  echo  "Applying proxy certificate trust to \"${CLUSTER_NAME}\" from \"${ADDITIONAL_CA_TRUST}\""

  local dest="/usr/local/share/ca-certificates/custom/"
  docker exec ${CLUSTER_NAME}-control-plane mkdir -p $dest
  docker cp ${ADDITIONAL_CA_TRUST}/. ${CLUSTER_NAME}-control-plane:${dest}
  docker exec ${CLUSTER_NAME}-control-plane update-ca-certificates
}

function apply_nginx_ingress() {
  echo "Launching NGINX ingress controller"
  
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
}

function install_cert_manager() {
  echo "Installing cert-manager"

  # Install cert-manager to manage TLS certificates
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

  kubectl -n cert-manager rollout status deploy/cert-manager
  kubectl -n cert-manager rollout status deploy/cert-manager-cainjector
  kubectl -n cert-manager rollout status deploy/cert-manager-webhook
}

# TODO: Need a teardown_docker_registry function.
function launch_docker_registry() {
  echo "Launching container registry \"${LOCAL_REGISTRY_NAME}\" at localhost:${LOCAL_REGISTRY_PORT}"

  local bridgeNetworkName="kind"
  local containerPortNumber="5000"

  # create registry container unless it already exists
  running="$(docker inspect -f '{{.State.Running}}' "${LOCAL_REGISTRY_NAME}" 2>/dev/null || true)"
  if [ "${running}" != 'true' ]; then
    echo "Starting registry \"${LOCAL_REGISTRY_NAME}\""
    docker run \
      -d --restart=always -p "127.0.0.1:${LOCAL_REGISTRY_PORT}:${containerPortNumber}" --name "${LOCAL_REGISTRY_NAME}" \
      registry:2
  else
    echo "Registry \"${LOCAL_REGISTRY_NAME}\" is already running."
  fi

  connectedItem=$(docker network inspect "${bridgeNetworkName}" -f '{{json .Containers}}' | jq '.[].Name' | grep ${LOCAL_REGISTRY_NAME} | sed "s|\"||g")
  if [ "${LOCAL_REGISTRY_NAME}" != "${connectedItem}" ]; then
    # connect the registry to the cluster network
    echo "Connecting registry \"${LOCAL_REGISTRY_NAME}\""
    docker network connect "${bridgeNetworkName}" "${LOCAL_REGISTRY_NAME}" || true
  else
    echo "Registry \"${LOCAL_REGISTRY_NAME}\" is already connected."
  fi

  # Document the local registry
  # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
  applyPopulatedTemplate ../config/local-registry-template.yaml ${CLUSTER_TMP}/${CLUSTER_NAME}_registry_config.yaml
}

function pull_docker_images() {
  echo "Pulling docker images for Fabric ${FABRIC_VERSION}"

  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-ca:$FABRIC_CA_VERSION || true
  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-orderer:$FABRIC_VERSION || true
  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-peer:$FABRIC_VERSION || true
  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-tools:$FABRIC_VERSION || true
  docker pull ${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}fluent/fluentd:v1.14.6-1.1
  docker pull ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/metadata-chaincode:v0.0.0 || true
  docker pull ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/content-chaincode:v0.0.0 || true
  docker pull ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/relationship-chaincode:v0.0.0 || true
  docker pull ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphjob:0.0.1 || true
  docker pull ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphprocessor:0.0.1 || true
  docker pull ${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}curlimages/curl:7.83.1 || true # For route diagnostics
  #docker pull ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/obsidian-lightswitch:v0.0.0 || true
}

function load_docker_images() {
  echo "Loading docker images into the control plane"

  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-ca:$FABRIC_CA_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-orderer:$FABRIC_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-peer:$FABRIC_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-tools:$FABRIC_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}fluent/fluentd:v1.14.6-1.1 --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/content-chaincode:v0.0.0 --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/metadata-chaincode:v0.0.0 --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/relationship-chaincode:v0.0.0 --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphjob:0.0.1 --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/graphprocessor:0.0.1 --name ${CLUSTER_NAME}
  kind load docker-image ${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}curlimages/curl:7.83.1 --name ${CLUSTER_NAME}
  #kind load docker-image ${DOCKER_REGISTRY_PROXY}${GHCR_IO}lmco/chaordicledger/obsidian-lightswitch:v0.0.0 --name ${CLUSTER_NAME}
}
