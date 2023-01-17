#!/bin/sh

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing hyperledger chaincode creation functions."
fi

CHAINCODE_TMP_DIR=${TEMP_DIR}/chaincode
mkdir -p $CHAINCODE_TMP_DIR

function package_chaincode_for() {
  local org=$1
  local ccname=$2

  local cc_folder="../../chaincode/${ccname}/ledger"

  if [ -d "$cc_folder" ]; then
    local build_folder="build/chaincode"
    local cc_archive="${build_folder}/${ccname}.tgz"
    syslog "Packaging chaincode folder ${cc_folder}"

    mkdir -p ${build_folder}

    cat ${cc_folder}/connection.json

    tar -C ${cc_folder} -zcf ${cc_folder}/code.tar.gz connection.json

    cat ${cc_folder}/metadata.json

    tar -C ${cc_folder} -zcf ${cc_archive} code.tar.gz metadata.json

    rm ${cc_folder}/code.tar.gz
  else
    syserr "Error: ${cc_folder} not found. Cannot continue."
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
  syslog "Transferring chaincode archive to ${org}"

  # Like kubectl cp, but targeted to a deployment rather than an individual pod.
  tar cf - ${cc_archive} | kubectl -n $NS exec -i deploy/${org}-admin-cli -c main -- tar xvf -
}

# Package and install the chaincode, but do not activate.
function install_chaincode() {
  local org=org$1
  local peercount=$2
  local ccname=$3

  syslog "install_chaincode ${org} ${peercount} ${ccname}"

  package_chaincode_for ${org} ${ccname}
  transfer_chaincode_archive_for ${org} ${ccname}

  local i=1
  for (( ; i<=${peercount}; i++))
  do
    # Install the chaincode
    echo 'set -x
    export CORE_PEER_ADDRESS='${org}'-peer'${i}':7051
    peer lifecycle chaincode install build/chaincode/'${ccname}'.tgz
    ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash
  done

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
  syslog "Launching chaincode container \"${ccimage}\" for ${org} ${PEER_NAME} ${ccname}"

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
  local orgname=$1
  local ccname=$2

  set_chaincode_id ${ccname}
  activate_chaincode_for ${orgname} $CHAINCODE_ID $ccname
}

function activate_chaincode_for() {
  local org=$1
  local cc_id=$2
  local ccname=$3
  syslog "Activating chaincode ${cc_id} for ${org}"

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
  local orgcount=$1
  local peercount=$2
  local ccimage=$3
  local ccname=$4

  syslog "Deploying chaincode ${orgcount} ${peercount} ${ccimage} ${ccname}"

  local i=1
  local j=1

  for (( ; i<=${orgcount}; i++))
  do
    for (( ; j<=${peercount}; j++))
    do
      syslog "find1: install_chaincode $i $j ${ccname}"
      install_chaincode $i $j ${ccname} 
      syslog "find2: launch_chaincode_service org${i} peer${j} ${ccimage} ${ccname}"
      launch_chaincode_service org${i} peer${j} ${ccimage} ${ccname}
    done

    syslog "find3: activate_chaincode org${i} ${ccname}"
    activate_chaincode org${i} ${ccname}
  done
}

function invoke_chaincode() {
  local ccname=$1
  export parameters=$2

  syslog "Chaincode Name=$ccname"
  syslog "Parameters=$parameters"

  export CHAINCODE_NAME=$ccname
  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  populateTemplate invoke_chaincode_template.sh ${CHANNEL_TMP_DIR}/${timestamp}_invoke_chaincode_${ccname}_${CHANNEL_NAME}.sh
  cat ${populatedTemplate} | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash
}

function query_chaincode() {
  local ccname=$1
  export parameters=$2
  
  export CHAINCODE_NAME=$ccname
  populateTemplate query_chaincode_template.sh ${CHANNEL_TMP_DIR}/query_chaincode_${ccname}_${CHANNEL_NAME}.sh
  cat ${populatedTemplate} | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash
}
