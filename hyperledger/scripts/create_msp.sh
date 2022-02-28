#!/bin/sh

# Reference: test-network-k8s/scripts/test_network.sh
MSP_TMP_DIR=/tmp/msp

function init_namespace() {
  echo "Creating namespace \"$NS\""

  kubectl create namespace $NS || true
}

function provision_persistent_volume()
{
  local orgnumber=$1
  local pv_config=$MSP_TMP_DIR/pv-fabric-org${orgnumber}.yaml

  echo "Provisioning volume storage for Org ${orgnumber}"

  # Provisions are special for org 0, others are consistent.

  if [ "$orgnumber" == "0" ]; then
    cat ../config/org/msp-root-pv-template.yaml |
      sed "s|{{ORG_NUMBER}}|${orgnumber}|" > ${pv_config}
  else
    cat ../config/org/msp-org-pv-template.yaml |
      sed "s|{{ORG_NUMBER}}|${orgnumber}|" > ${pv_config}
  fi

  kubectl create -f ${pv_config} || true
}

function claim_persistant_volume()
{
  local orgnumber=$1
  local pvc_config=$MSP_TMP_DIR/pvc-fabric-org${orgnumber}.yaml

  # Claims are consistent across orgs.
  echo "Claiming volume for Org ${orgnumber}"
  cat ../config/org/msp-pvc-template.yaml |
    sed "s|{{ORG_NUMBER}}|${orgnumber}|" > ${pvc_config}

  kubectl -n $NS create -f ${pvc_config} || true
}

function init_storage_volumes() {
  local orgcount=$1

  echo "Provisioning volume storage for ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    provision_persistent_volume ${i}
    claim_persistant_volume ${i}
  done
}

function load_org_config() {
  local orgcount=$1

  echo "Creating fabric config maps for ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    local dir=$MSP_TMP_DIR/config/org${i}
    mkdir -p ${dir}
    local caconfig=${dir}/fabric-ca-server-config.yaml
    echo "Creating fabric CA server config for org ${i}"
    cat ../config/org/fabric-ca-server-config-template.yaml |
      sed "s|{{ORG_NUMBER}}|${i}|" |
      sed "s|{{NETWORK_NAME}}|${NETWORK_NAME}|" > ${caconfig}
    
    # TODO: Perform this refactoring after this is confirmed working.
    cp ../config/toBeRefactored/org${i}/* ${dir}

    kubectl -n $NS delete configmap org${i}-config || true
    kubectl -n $NS create configmap org${i}-config --from-file=${dir}
  done
}

function init_tls_cert_issuers()
{
  echo "Initializing Root TLS certificate Issuers"

  local orgcount=$1

  # Create a self-signing certificate issuer / root TLS certificate for the blockchain.
  # TODO : Bring-Your-Own-Key - allow the network bootstrap to read an optional ECDSA key pair for the TLS trust root CA.
  kubectl -n $NS apply -f ../config/root-tls-cert-issuer.yaml
  kubectl -n $NS wait --timeout=30s --for=condition=Ready issuer/root-tls-cert-issuer

  echo "Creating TLS cert issuer for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    local msp_dir=${MSP_TMP_DIR}/kube/org${i}
    mkdir -p ${msp_dir}
    local issuer_config=${msp_dir}/org${i}-tls-cert-issuer.yaml
    echo "Creating org ${i} TLS cert issuer"
    cat ../config/org/tls-cert-issuer-template.yaml |
      sed "s|{{ORG_NUMBER}}|${i}|" > ${issuer_config}

    # Use the self-signing issuer to generate three Issuers, one for each org.
    kubectl -n $NS apply -f ${issuer_config}
    kubectl -n $NS wait --timeout=30s --for=condition=Ready issuer/org${i}-tls-cert-issuer
  done

  kubectl get certificate -n $NS
}

function launch_CA() {
  local number=$1
  local yaml=$2

  local msp_dir=$MSP_TMP_DIR/kube/org${number}/
  mkdir -p ${msp_dir}
  local ca_config_file=${msp_dir}/org${number}-ca.yaml

  cat ${yaml} \
    | sed 's,{{NETWORK_NAME}},'${NETWORK_NAME}',g' \
    | sed 's,{{ORG_NUMBER}},'${number}',g' \
    | sed 's,{{FABRIC_CONTAINER_REGISTRY}},'${FABRIC_CONTAINER_REGISTRY}',g' \
    | sed 's,{{FABRIC_CA_VERSION}},'${FABRIC_CA_VERSION}',g' > ${ca_config_file}

  cat ${ca_config_file} | kubectl -n $NS apply -f -
}

function launch_ECert_CAs()
{
  local orgcount=$1

  echo "Launching Fabric CAs for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    launch_CA ${i} ../config/org/ca-template.yaml
    kubectl -n $NS rollout status deploy/org${i}-ca
  done
}

function enroll_bootstrap_ECert_CA_users() {
  orgcount=$1

  echo "Enrolling bootstrap ECert CA users for ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    local org=org${i}
    local auth=${RCAADMIN_AUTH}
    local ecert_ca=${org}-ca

    echo 'set -x
    fabric-ca-client enroll \
      --url https://'${auth}'@'${ecert_ca}' \
      --tls.certfiles /var/hyperledger/fabric/config/tls/ca.crt \
      --mspdir $FABRIC_CA_CLIENT_HOME/'${ecert_ca}'/rcaadmin/msp
    ' | exec kubectl -n $NS exec deploy/${ecert_ca} -i -- /bin/sh
  done
}

function create_local_MSPs()
{
  local orgcount=$1

  echo "Creating an MSP for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    # cat enroll_admin_with_ca_client.sh |
    #   sed "s|{{ORG_NUMBER}}|${i}|g" |
    #   exec kubectl -n $NS exec deploy/org${i}-ca -i -- /bin/sh

    for ((j=1; j<=${orderercount}; j++))
    do
      #TODO: Note: peer1 is currently hard-coded.
      cat enroll_msp_with_ca_client.sh |
        sed "s|{{ORG_NUMBER}}|${i}|g" |
        sed "s|{{ORDERER_NUMBER}}|${j}|g" |
        exec kubectl -n $NS exec deploy/org${i}-ca -i -- /bin/sh
    done
  done

  # Ref create_org0_local_MSP in test_network.sh


}

function launch() {
  local yaml=$1
  local orgnumber=$2
  local orderernumber=$3
  local msp_dir=$MSP_TMP_DIR/kube/org${number}/
  mkdir -p ${msp_dir}
  local orderer_config_file=${msp_dir}/org${number}_orderer${orderernumber}.yaml

  cat ${yaml} \
    | sed 's,{{NETWORK_NAME}},'${NETWORK_NAME}',g' \
    | sed 's,{{ORG_NUMBER}},'${orgnumber}',g' \
    | sed 's,{{ORDERER_NUMBER}},'${orderernumber}',g' \
    | sed 's,{{FABRIC_CONTAINER_REGISTRY}},'${FABRIC_CONTAINER_REGISTRY}',g' \
    | sed 's,{{FABRIC_VERSION}},'${FABRIC_VERSION}',g' > ${orderer_config_file}

  cat ${orderer_config_file} | kubectl -n $NS apply -f -
}

function launch_orderers() {
  local orgcount=$1
  local orderercount=$2
  echo "Launching ${orderercount} orderer(s) for each of ${orgcount} org(s)"

  #for ((i=0; i<${orgcount}; i++))
  #Only launch orderers for Org 0
  for ((i=0; i<1; i++))
  do
    for ((j=1; j<=${orderercount}; j++))
    do
      launch ../config/org/orderer-template.yaml ${i} ${j}
      kubectl -n $NS rollout status deploy/org${i}-orderer${j}
    done
  done
}

function launch_peers() {
  local orgcount=$1
  local peercount=$2
  echo "Launching ${peercount} peer(s) for each of ${orgcount} non-root org(s)"

  # TODO: Note: peer-template.yaml currently has peer1 hard-coded.

  # Launch no peers for Org 0
  for ((i=1; i<=${orgcount}; i++))
  do
    for ((j=1; j<=${peercount}; j++))
    do
      local msp_dir=$MSP_TMP_DIR/kube/org${i}
      mkdir -p ${msp_dir}
      local peer_config_file=${msp_dir}/org${i}-peer${j}.yaml
      cat ../config/org/peer-template.yaml \
        | sed 's,{{PEER_NUMBER}},'${j}',g' \
        | sed 's,{{NETWORK_NAME}},'${NETWORK_NAME}',g' \
        | sed 's,{{ORG_NUMBER}},'${i}',g' \
        | sed 's,{{FABRIC_CONTAINER_REGISTRY}},'${FABRIC_CONTAINER_REGISTRY}',g' \
        | sed 's,{{FABRIC_VERSION}},'${FABRIC_VERSION}',g' > ${peer_config_file}

      cat ${peer_config_file} | kubectl -n $NS apply -f -
      
      kubectl -n $NS rollout status deploy/org${i}-peer${j}
    done
  done
}

# TLS certificates are isused by the CA's Issuer, stored in a Kube secret, and mounted into the pod at /var/hyperledger/fabric/config/tls.
# For consistency with the Fabric-CA guide, his function copies the orderer's TLS certs into the traditional Fabric MSP / folder structure.
function extract_orderer_tls_cert() {
  local orgnumber=$1
  local orderer=$2

  echo "set -x

  mkdir -p /var/hyperledger/fabric/organizations/ordererOrganizations/org${orgnumber}.example.com/orderers/${orderer}.org${orgnumber}.example.com/tls/signcerts/

  cp \
    var/hyperledger/fabric/config/tls/tls.crt \
    /var/hyperledger/fabric/organizations/ordererOrganizations/org${orgnumber}.example.com/orderers/${orderer}.org${orgnumber}.example.com/tls/signcerts/cert.pem

  " | exec kubectl -n $NS exec deploy/${orderer} -i -c main -- /bin/sh
}

function extract_orderer_tls_certs() {
  echo "Extracting orderer TLS certs to local MSP folder"
  orgcount=$1
  orderercount=$2

  for ((i=0; i<${orgcount}; i++))
  do
    for ((j=1; j<=${orderercount}; j++))
    do
      extract_orderer_tls_cert ${i} org${i}-orderer${j}
    done
  done
}

function create_msp() {
  local orgcount=$1
  shift
  local orderercount=$1
  shift
  local peercount=$1

  mkdir -p $MSP_TMP_DIR

  init_namespace
  init_storage_volumes $orgcount
  load_org_config $orgcount
  init_tls_cert_issuers $orgcount
  launch_ECert_CAs $orgcount
  enroll_bootstrap_ECert_CA_users $orgcount
  create_local_MSPs $orgcount $orderercount
  launch_orderers $orgcount $orderercount
  launch_peers $orgcount $peercount

  extract_orderer_tls_certs $orgcount $orderercount
}

function purge_storage_volumes() {
  kubectl delete pv --all
}

function purge_storage_volume_claims() {
  kubectl delete pvc --all
}
