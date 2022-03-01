#!/bin/sh

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
  echo "Creating cluster \"${CLUSTER_NAME}\""

  local cluster_config=/tmp/cluster_config.yaml

  cat ../config/cluster-template.yaml | 
    sed "s|\${ingress_http_port}|${NGINX_HTTP_PORT}|g" |
    sed "s|\${ingress_https_port}|${NGINX_HTTPS_PORT}|g" |
    sed "s|\${reg_name}|${LOCAL_REGISTRY_NAME}|g" |
    sed "s|\${reg_port}|${LOCAL_REGISTRY_PORT}|g" > ${cluster_config}

  kind create cluster --name $CLUSTER_NAME --config=${cluster_config}

  rm ${cluster_config}
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

  # create registry container unless it already exists
  local reg_name=${LOCAL_REGISTRY_NAME}
  local reg_port=${LOCAL_REGISTRY_PORT}

  running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
  if [ "${running}" != 'true' ]; then
    echo "Starting registry \"${reg_name}\""
    docker run \
      -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
      registry:2
  else
    echo "Registry \"${reg_name}\" is already running."
  fi

  connectedItem=$(docker network inspect "kind" -f '{{json .Containers}}' | jq '.[].Name' | grep ${reg_name} | sed "s|\"||g")
  if [ "${reg_name}" != "${connectedItem}"]; then
    # connect the registry to the cluster network
    # (the network may already be connected)
    echo "Connecting registry \"${reg_name}\""
    docker network connect "kind" "${reg_name}" || true
  else
    echo "Registry \"${reg_name}\" is already connected."
  fi

  # Document the local registry
  # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
  local reg_config=/tmp/local-registry.yaml

  cat ../config/local-registry-template.yaml | 
    sed "s|\${reg_port}|${LOCAL_REGISTRY_PORT}|g" > ${reg_config}

  kubectl apply -f ${reg_config}

  rm ${reg_config}
}

function pull_docker_images() {
  echo "Pulling docker images for Fabric ${FABRIC_VERSION}"

  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-ca:$FABRIC_CA_VERSION
  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-orderer:$FABRIC_VERSION
  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-peer:$FABRIC_VERSION
  docker pull ${FABRIC_CONTAINER_REGISTRY}/fabric-tools:$FABRIC_VERSION
}

function load_docker_images() {
  echo "Loading docker images into the control plane"

  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-ca:$FABRIC_CA_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-orderer:$FABRIC_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-peer:$FABRIC_VERSION --name ${CLUSTER_NAME}
  kind load docker-image ${FABRIC_CONTAINER_REGISTRY}/fabric-tools:$FABRIC_VERSION --name ${CLUSTER_NAME}
  kind load docker-image localhost:5000/test/mypeer:latest --name ${CLUSTER_NAME}
}
