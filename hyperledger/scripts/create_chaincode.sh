#!/bin/sh

CHAINCODE_TMP_DIR=${TEMP_DIR}/chaincode
mkdir -p $CHAINCODE_TMP_DIR

function package_chaincode_for() {
  local org=$1
  local ccname=$2

  local cc_folder="../../chaincode/${ccname}/ledger"

  if [ -d "$cc_folder" ]; then
    local build_folder="build/chaincode"
    local cc_archive="${build_folder}/${ccname}.tgz"
    echo "Packaging chaincode folder ${cc_folder}"

    mkdir -p ${build_folder}

    cat ${cc_folder}/connection.json

    tar -C ${cc_folder} -zcf ${cc_folder}/code.tar.gz connection.json

    cat ${cc_folder}/metadata.json

    tar -C ${cc_folder} -zcf ${cc_archive} code.tar.gz metadata.json

    rm ${cc_folder}/code.tar.gz
  else
    echo "Error: ${cc_folder} not found. Can not continue."
    exit 1
  fi
}

# Copy the chaincode archive from the local host to the org admin
function transfer_chaincode_archive_for() {
  # local org=$1
  # local cc_archive="${CHAINCODE_TMP_DIR}/build/${CHAINCODE_NAME}.tgz"
  # echo "Transferring chaincode archive to ${org}"
  # pushd ${CHAINCODE_TMP_DIR}/build
  # # Like kubectl cp, but targeted to a deployment rather than an individual pod.
  # tar cf - ${CHAINCODE_NAME}.tgz | kubectl -n $NS exec -i deploy/${org}-admin-cli -c main -- tar xvf -
  # popd

  local org=$1
  local ccname=$2
  local cc_archive="build/chaincode/${ccname}.tgz"
  echo "Transferring chaincode archive to ${org}"

  # Like kubectl cp, but targeted to a deployment rather than an individual pod.
  tar cf - ${cc_archive} | kubectl -n $NS exec -i deploy/${org}-admin-cli -c main -- tar xvf -
}

function install_chaincode_for() {
  local org=$1
  local peer=$2
  local ccname=$3
  echo "Installing chaincode ${ccname} for ${org} ${peer}"

  # Install the chaincode
  echo 'set -x
  export CORE_PEER_ADDRESS='${org}'-'${peer}':7051
  peer lifecycle chaincode install build/chaincode/'${ccname}'.tgz
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash

  # local org=$1
  # local peer=$2
  # echo "Installing chaincode for org ${org} peer ${peer}"

  # # Install the chaincode
  # echo 'set -x
  # export CORE_PEER_ADDRESS='${org}'-'${peer}':7051
  # peer lifecycle chaincode install '${CHAINCODE_NAME}'.tgz
  # ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash

  # # # Install the chaincode
  # # echo 'set -x
  # # export CORE_PEER_ADDRESS='${org}'-'${peer}':7051
  # # peer lifecycle chaincode install '${CHAINCODE_TMP_DIR}'/build/'${CHAINCODE_NAME}'.tgz
  # # ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash
}


# Package and install the chaincode, but do not activate.
function install_chaincode() {
  local org=org1
  local ccname=$1

  package_chaincode_for ${org} ${ccname}
  transfer_chaincode_archive_for ${org} ${ccname}
  install_chaincode_for ${org} peer1 ${ccname}
  install_chaincode_for ${org} peer2 ${ccname}

  set_chaincode_id ${ccname}
}

# Normally the chaincode ID is emitted by the peer install command.  In this case, we'll generate the
# package ID as the sha-256 checksum of the chaincode archive.
function set_chaincode_id() {
  local ccname=$1
  local cc_package=build/chaincode/${ccname}.tgz
  cc_sha256=$(shasum -a 256 ${cc_package} | tr -s ' ' | cut -d ' ' -f 1)

  label=$( jq -r '.label' ../../chaincode/${ccname}/ledger/metadata.json)

  export CHAINCODE_ID=${label}:${cc_sha256}
}

function launch_chaincode_service() {
  local org=$1
  export PEER_NAME=$2
  local ccimage=$3
  local ccname=$4
  echo "Launching chaincode container \"${ccimage}\""

  # The chaincode endpoint needs to have the generated chaincode ID available in the environment.
  # This could be from a config map, a secret, or by directly editing the deployment spec.  Here we'll keep
  # things simple by using sed to substitute script variables into a yaml template.
  export ORG_NUMBER=
  export CHAINCODE_IMAGE=$ccimage
  export CHAINCODE_NAME=$ccname

  applyPopulatedTemplate ../config/${org}-cc-template.yaml $CHAINCODE_TMP_DIR/${org}-${PEER_NAME}-cc-${ccname}.yaml $NS
  kubectl -n $NS rollout status deploy/${org}-${PEER_NAME}-cc-${ccname}
}

# Activate the installed chaincode but do not package/install a new archive.
function activate_chaincode() {
  set -x
  local ccname=$1

  set_chaincode_id ${ccname}
  activate_chaincode_for org1 $CHAINCODE_ID $ccname
}

function activate_chaincode_for() {
  local org=$1
  local cc_id=$2
  local ccname=$3
  echo "Activating chaincode ${cc_id}"

  echo 'set -x 
  export CORE_PEER_ADDRESS='${org}'-peer1:7051
  
  peer lifecycle \
    chaincode approveformyorg \
    --channelID '${CHANNEL_NAME}' \
    --name '${ccname}' \
    --version 1 \
    --package-id '${cc_id}' \
    --sequence 1 \
    -o org0-orderer1:6050 \
    --tls false --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  
  peer lifecycle \
    chaincode commit \
    --channelID '${CHANNEL_NAME}' \
    --name '${ccname}' \
    --version 1 \
    --sequence 1 \
    -o org0-orderer1:6050 \
    --tls false --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash
}

# Install, launch, and activate the chaincode
function deploy_chaincode() {
  set -x

  local ccimage=$1
  local ccname=$2

  install_chaincode ${ccname}
  launch_chaincode_service org1 peer1 ${ccimage} ${ccname}
  launch_chaincode_service org1 peer2 ${ccimage} ${ccname}

  activate_chaincode ${ccname}
}

function invoke_chaincode() {
  local ccname=$1
  export parameters=$2

  echo "Chaincode Name=$ccname"
  echo "Parameters=$parameters"

  export CHAINCODE_NAME=$ccname
  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  populateTemplate invoke_chaincode_template.sh ${CHANNEL_TMP_DIR}/${timestamp}_invoke_chaincode_${ccname}_${CHANNEL_NAME}_.sh
  cat ${populatedTemplate} | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash
}

function query_chaincode() {
  local ccname=$1
  export parameters=$2
  
  export CHAINCODE_NAME=$ccname
  populateTemplate query_chaincode_template.sh ${CHANNEL_TMP_DIR}/query_chaincode_${ccname}_${CHANNEL_NAME}.sh
  cat ${populatedTemplate} | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash
}
