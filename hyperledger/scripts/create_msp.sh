#!/bin/sh

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing hyperledger MSP creation functions."
fi

# Reference: test-network-k8s/scripts/test_network.sh
MSP_TMP_DIR=${TEMP_DIR}/msp
mkdir -p ${MSP_TMP_DIR}

function init_namespace() {
  syslog "Creating namespace \"$NS\""

  kubectl create namespace $NS || true
}

function provision_persistent_volume()
{
  export ORG_NUMBER=$1
  local pv_config=$MSP_TMP_DIR/pv-fabric-org${ORG_NUMBER}.yaml

  syslog "Provisioning volume storage for Org ${ORG_NUMBER}"

  # Provisions are special for org 0, others are consistent.

  if [ "$ORG_NUMBER" == "0" ]; then
    populateTemplate ../config/org/msp-root-pv-template.yaml ${pv_config}
    # cat ../config/org/msp-root-pv-template.yaml |
    #   sed "s|${ORG_NUMBER}|${orgnumber}|" > ${pv_config}
  else
    populateTemplate ../config/org/msp-org-pv-template.yaml ${pv_config}
    # cat ../config/org/msp-org-pv-template.yaml |
    #   sed "s|${ORG_NUMBER}|${orgnumber}|" > ${pv_config}
  fi

  kubectl create -f ${pv_config} || true
}

function claim_persistant_volume()
{
  export ORG_NUMBER=$1
  local pvc_config=$MSP_TMP_DIR/pvc-fabric-org${ORG_NUMBER}.yaml

  # Claims are consistent across orgs.
  syslog "Claiming volume for Org ${ORG_NUMBER}"

  populateTemplate ../config/org/msp-pvc-template.yaml ${pvc_config}
  # cat ../config/org/msp-pvc-template.yaml |
  #   sed "s|${ORG_NUMBER}|${orgnumber}|" > ${pvc_config}

  kubectl -n $NS create -f ${pvc_config} || true
}

function init_storage_volumes() {
  local orgcount=$1

  syslog "Provisioning volume storage for ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    provision_persistent_volume ${i}
    claim_persistant_volume ${i}
  done
}

function load_org_config() {
  local orgcount=$1

  syslog "Creating fabric config maps for ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    local dir=$MSP_TMP_DIR/config/org${i}
    mkdir -p ${dir}
    local caconfig=${dir}/fabric-ca-server-config.yaml
    syslog "Creating fabric CA server config for org ${i}"
    export ORG_NUMBER=${i}
    populateTemplate ../config/org/fabric-ca-server-config-template.yaml ${caconfig}
    # cat ../config/org/fabric-ca-server-config-template.yaml |
    #   sed "s|${ORG_NUMBER}|${i}|" |
    #   sed "s|${NETWORK_NAME}|${NETWORK_NAME}|" > ${caconfig}
    
    # TODO: Perform this refactoring after this is confirmed working.
    cp ../config/toBeRefactored/org${i}/*.yaml ${dir}

    kubectl -n $NS create configmap org${i}-config --from-file=${dir} -o yaml --dry-run=client | kubectl apply -f -
  done
}

function init_tls_cert_issuers()
{
  syslog "Initializing Root TLS certificate Issuers"

  local orgcount=$1

  # Create a self-signing certificate issuer / root TLS certificate for the blockchain.
  # TODO : Bring-Your-Own-Key - allow the network bootstrap to read an optional ECDSA key pair for the TLS trust root CA.
  kubectl -n $NS apply -f ../config/root-tls-cert-issuer.yaml
  kubectl -n $NS wait --timeout=30s --for=condition=Ready issuer/root-tls-cert-issuer

  syslog "Creating TLS cert issuer for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    local msp_dir=${MSP_TMP_DIR}/kube/org${i}
    mkdir -p ${msp_dir}
    local issuer_config=${msp_dir}/org${i}-tls-cert-issuer.yaml
    syslog "Creating org ${i} TLS cert issuer"
    export ORG_NUMBER=${i}
    populateTemplate ../config/org/tls-cert-issuer-template.yaml ${issuer_config}
    # cat ../config/org/tls-cert-issuer-template.yaml |
    #   sed "s|${ORG_NUMBER}|${i}|" > ${issuer_config}

    # Use the self-signing issuer to generate three Issuers, one for each org.
    kubectl -n $NS apply -f ${issuer_config}
    kubectl -n $NS wait --timeout=30s --for=condition=Ready issuer/org${i}-tls-cert-issuer
  done

  kubectl get certificate -n $NS
}

function launch_CA() {
  local number=$1
  local yaml=$2

  local msp_dir=$MSP_TMP_DIR/kube/org${number}
  mkdir -p ${msp_dir}
  local ca_config_file=${msp_dir}/org${number}-ca.yaml

  export ORG_NUMBER=${number}
  populateTemplate ${yaml} ${ca_config_file}
  # cat ${yaml} \
  #   | sed 's,${NETWORK_NAME},'${NETWORK_NAME}',g' \
  #   | sed 's,${ORG_NUMBER},'${number}',g' \
  #   | sed 's,${FABRIC_CONTAINER_REGISTRY},'${FABRIC_CONTAINER_REGISTRY}',g' \
  #   | sed 's,${FABRIC_CA_VERSION},'${FABRIC_CA_VERSION}',g' > ${ca_config_file}

  cat ${ca_config_file} | kubectl -n $NS apply -f -
}

function launch_ECert_CAs()
{
  local orgcount=$1

  syslog "Launching Fabric CAs for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    launch_CA ${i} ../config/org/ca-template.yaml
    kubectl -n $NS rollout status deploy/org${i}-ca
  done
}

function enroll_bootstrap_ECert_CA_users() {
  orgcount=$1

  syslog "Enrolling bootstrap ECert CA users for ${orgcount} org(s)"

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
  local orderercount=$2
  local peercount=$3

  syslog "Creating an MSP for each of ${orgcount} org(s)"

  local i=0

  local msp_dir=$MSP_TMP_DIR/org${i}
  mkdir -p $msp_dir

  local config_file=${msp_dir}/enroll_admin_msp_with_ca_client.sh

  # Setting this to the string literal '$FABRIC_CA_CLIENT_HOME' so that the variable remains
  # in the resulting scripts after env var replacement is complete.
  export FABRIC_CA_CLIENT_HOME="\$FABRIC_CA_CLIENT_HOME"

  export ORG_NUMBER="0"
  populateTemplate ../config/enroll_admin_with_ca_client_template.sh ${config_file}

  cat ${config_file} | exec kubectl -n $NS exec deploy/org0-ca -i -- /bin/sh

  local config_file=${msp_dir}/enroll_root_msp_with_ca_client.sh

  for ((j=1; j<=${orderercount}; j++))
  do
    export ORDERER_NUMBER=${j}
    syslog "Registering and Enrolling Org ${i} Orderer ${j}"
    local config_file=${msp_dir}/enroll_msp_org${i}_orderer${j}_with_ca_client.sh
    populateTemplate ../config/enroll_msp_orderer_with_ca_client_template.sh ${config_file}
    cat ${config_file} | exec kubectl -n $NS exec deploy/org0-ca -i -- /bin/sh
  done

  for ((i=1; i<${orgcount}; i++))
  do
    syslog "Creating MSP for Org ${i}"
    local msp_dir=$MSP_TMP_DIR/org${i}
    mkdir -p $msp_dir
    
    # export ORG_NUMBER=${i}
    # local config_file=${msp_dir}/enroll_msp_org${i}_peer${j}_with_ca_client.sh
    # export PEER_NUMBER=${j}
    # populateTemplate ../config/enroll_msp_peer_with_ca_client_template.sh ${config_file}

    export ORG_NUMBER=${i}

    # local config_file=${msp_dir}/enroll_org${i}_admin_msp_with_ca_client.sh
    # populateTemplate ../config/enroll_admin_with_ca_client_template.sh ${config_file}
    # cat ${config_file} | exec kubectl -n $NS exec deploy/org${i}-ca -i -- /bin/sh

    local config_file=${msp_dir}/enroll_msp_org${i}_peer${j}_with_ca_client.sh
    export PEER_NUMBER=${j}
    populateTemplate ../config/toBeRefactored/org${i}/enroll_msp_with_ca_client_template.sh ${config_file}

    # for ((j=1; j<=${peercount}; j++))
    # do
    #   local config_file=${msp_dir}/enroll_msp_org${i}_peer${j}_with_ca_client.sh
    #   export PEER_NUMBER=${j}
    #   populateTemplate ../config/enroll_msp_peer_with_ca_client_template.sh ${config_file}
    # done

    cat ${config_file} | exec kubectl -n $NS exec deploy/org${i}-ca -i -- /bin/sh

  done
}

function launch() {
  local yaml=$1
  local orgnumber=$2
  local orderernumber=$3
  local msp_dir=$MSP_TMP_DIR/kube/org${orgnumber}/
  mkdir -p ${msp_dir}
  local orderer_config_file=${msp_dir}/org${orgnumber}_orderer${orderernumber}.yaml

  export ORG_NUMBER=${orgnumber}
  export ORDERER_NUMBER=${orderernumber}
  populateTemplate ${yaml} ${orderer_config_file}

  # cat ${yaml} \
  #   | sed 's,${NETWORK_NAME},'${NETWORK_NAME}',g' \
  #   | sed 's,${ORG_NUMBER},'${orgnumber}',g' \
  #   | sed 's,${ORDERER_NUMBER},'${orderernumber}',g' \
  #   | sed 's,${FABRIC_CONTAINER_REGISTRY},'${FABRIC_CONTAINER_REGISTRY}',g' \
  #   | sed 's,${FABRIC_VERSION},'${FABRIC_VERSION}',g' > ${orderer_config_file}

  cat ${orderer_config_file} | kubectl -n $NS apply -f -
}

function launch_orderers() {
  local orgcount=$1
  local orderercount=$2
  syslog "Launching ${orderercount} orderer(s) for each of ${orgcount} org(s)"

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
  local nonroot=$((${orgcount}-1))
  syslog "Launching ${peercount} peer(s) for each of ${nonroot} non-root org(s)"

  # Launch no peers for Org 0
  for ((i=1; i<${orgcount}; i++))
  do
    for ((j=1; j<=${peercount}; j++))
    do
      local msp_dir=$MSP_TMP_DIR/kube/org${i}
      mkdir -p ${msp_dir}
      local peer_config_file=${msp_dir}/org${i}-peer${j}.yaml

      syslog "Creating config for Org ${i} Peer ${j} as ${peer_config_file}"

      export ORG_NUMBER=${i}
      export PEER_NUMBER=${j}
      populateTemplate ../config/org/peer-template.yaml ${peer_config_file}
      # cat ../config/org/peer-template.yaml \
      #   | sed 's,${PEER_NUMBER},'${j}',g' \
      #   | sed 's,${NETWORK_NAME},'${NETWORK_NAME}',g' \
      #   | sed 's,${ORG_NUMBER},'${i}',g' \
      #   | sed 's,${FABRIC_CONTAINER_REGISTRY},'${FABRIC_CONTAINER_REGISTRY}',g' \
      #   | sed 's,${FABRIC_VERSION},'${FABRIC_VERSION}',g' > ${peer_config_file}

      cat ${peer_config_file} | kubectl -n $NS apply -f -
      
      syslog "Creating config for Org ${i} Peer ${j}"
      kubectl -n $NS rollout status deploy/org${i}-peer${j}
    done

    # Only launch one peer gateway service per org.
    local msp_dir=$MSP_TMP_DIR/kube/org${i}
    mkdir -p ${msp_dir}
    local peer_gateway_config_file=${msp_dir}/org${i}-peer-gateway.yaml

    export ORG_NUMBER=${i}
    populateTemplate ../config/org/peer-gateway-service-template.yaml ${peer_gateway_config_file}
    # cat ../config/org/peer-gateway-service-template.yaml \
    #   | sed 's,${ORG_NUMBER},'${i}',g' > ${peer_gateway_config_file}

    cat ${peer_gateway_config_file} | kubectl -n $NS apply -f -
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
  syslog "Extracting orderer TLS certs to local MSP folder"
  orgcount=$1
  orderercount=$2

  for ((j=1; j<=${orderercount}; j++))
  do
    extract_orderer_tls_cert 0 org0-orderer${j}
  done
}

function create_msp() {
  local orgcount=$1
  shift
  local orderercount=$1
  shift
  local peercount=$1

  init_namespace
  init_storage_volumes $orgcount
  load_org_config $orgcount
  init_tls_cert_issuers $orgcount
  launch_ECert_CAs $orgcount
  enroll_bootstrap_ECert_CA_users $orgcount
  create_local_MSPs $orgcount $orderercount $peercount
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
