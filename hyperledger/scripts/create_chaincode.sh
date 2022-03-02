#!/bin/sh

CHAINCODE_TMP_DIR=/tmp/chaincode

function package_chaincode_for() {
  local org=$1
  local cc_folder="../../chaincode/${CHAINCODE_NAME}"
  local build_folder="build/chaincode"
  local cc_archive="${build_folder}/${CHAINCODE_NAME}.tgz"
  echo "Packaging chaincode folder ${cc_folder}"

  mkdir -p ${build_folder}

  tar -C ${cc_folder} -zcf ${cc_folder}/code.tar.gz connection.json
  tar -C ${cc_folder} -zcf ${cc_archive} code.tar.gz metadata.json

  rm ${cc_folder}/code.tar.gz
}

# Copy the chaincode archive from the local host to the org admin
function transfer_chaincode_archive_for() {
  local org=$1
  local cc_archive="build/chaincode/${CHAINCODE_NAME}.tgz"
  echo "Transferring chaincode archive to ${org}"

  # Like kubectl cp, but targeted to a deployment rather than an individual pod.
  tar cf - ${cc_archive} | kubectl -n $NS exec -i deploy/${org}-admin-cli -c main -- tar xvf -
}

function install_chaincode_for() {
  local org=$1
  local peer=$2
  echo "Installing chaincode for org ${org} peer ${peer}"

  # Install the chaincode
  echo 'set -x
  export CORE_PEER_ADDRESS='${org}'-'${peer}':7051
  peer lifecycle chaincode install build/chaincode/'${CHAINCODE_NAME}'.tgz
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash
}


# Package and install the chaincode, but do not activate.
function install_chaincode() {
  local org=org1

  package_chaincode_for ${org}
  transfer_chaincode_archive_for ${org}
  install_chaincode_for ${org} peer1
  install_chaincode_for ${org} peer2

  set_chaincode_id
}

# Normally the chaincode ID is emitted by the peer install command.  In this case, we'll generate the
# package ID as the sha-256 checksum of the chaincode archive.
function set_chaincode_id() {
  local cc_package=build/chaincode/${CHAINCODE_NAME}.tgz
  cc_sha256=$(shasum -a 256 ${cc_package} | tr -s ' ' | cut -d ' ' -f 1)

  label=$( jq -r '.label' ../../chaincode/${CHAINCODE_NAME}/metadata.json)

  CHAINCODE_ID=${label}:${cc_sha256}
}

function launch_chaincode_service() {
  local org=$1
  local cc_id=$2
  local cc_image=$3
  local peer=$4
  echo "Launching chaincode container \"${cc_image}\""

  # The chaincode endpoint needs to have the generated chaincode ID available in the environment.
  # This could be from a config map, a secret, or by directly editing the deployment spec.  Here we'll keep
  # things simple by using sed to substitute script variables into a yaml template.
  cat ../config/${org}-cc-template.yaml \
    | sed 's,{{CHAINCODE_NAME}},'${CHAINCODE_NAME}',g' \
    | sed 's,{{CHAINCODE_ID}},'${cc_id}',g' \
    | sed 's,{{CHAINCODE_IMAGE}},'${cc_image}',g' \
    | sed 's,{{PEER_NAME}},'${peer}',g' \
    | exec kubectl -n $NS apply -f -

  kubectl -n $NS rollout status deploy/${org}${peer}-cc-${CHAINCODE_NAME}
}

# Activate the installed chaincode but do not package/install a new archive.
function activate_chaincode() {
  set -x

  set_chaincode_id
  activate_chaincode_for org1 $CHAINCODE_ID
}

function activate_chaincode_for() {
  local org=$1
  local cc_id=$2
  echo "Activating chaincode ${CHAINCODE_ID}"

  echo 'set -x 
  export CORE_PEER_ADDRESS='${org}'-peer1:7051
  
  peer lifecycle \
    chaincode approveformyorg \
    --channelID '${CHANNEL_NAME}' \
    --name '${CHAINCODE_NAME}' \
    --version 1 \
    --package-id '${cc_id}' \
    --sequence 1 \
    -o org0-orderer1:6050 \
    --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  
  peer lifecycle \
    chaincode commit \
    --channelID '${CHANNEL_NAME}' \
    --name '${CHAINCODE_NAME}' \
    --version 1 \
    --sequence 1 \
    -o org0-orderer1:6050 \
    --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash
}

# Install, launch, and activate the chaincode
function deploy_chaincode() {
  set -x

  install_chaincode
  launch_chaincode_service org1 $CHAINCODE_ID $CHAINCODE_IMAGE peer1
  launch_chaincode_service org1 $CHAINCODE_ID $CHAINCODE_IMAGE peer2
  activate_chaincode
}

function invoke_chaincode() {
  params=$1
  mkdir -p $CHANNEL_TMP_DIR

  local execscript=${CHANNEL_TMP_DIR}/invoke_chaincode_${CHAINCODE_NAME}_${CHANNEL_NAME}.sh

  cat invoke_chaincode_template.sh |
    sed "s|{{CHAINCODE_NAME}}|${CHAINCODE_NAME}|g" |
    sed "s|{{CHANNEL_NAME}}|${CHANNEL_NAME}|g" |
    sed "s|{{parameters}}|$params|g" > ${execscript}
  
  cat ${execscript} | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash

  sleep 2
}

function query_chaincode() {
  set -x
  # todo: mangle additional $@ parameters with bash escape quotations
  echo '
  export CORE_PEER_ADDRESS=org1-peer1:7051
  peer chaincode query -n '${CHAINCODE_NAME}' -C '${CHANNEL_NAME}' -c '"'$@'"'
  ' | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash
}
