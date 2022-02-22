#!/bin/sh

# Reference: test-network-k8s/scripts/test_network.sh

function init_namespace() {
  echo "Creating namespace \"$NS\""

  kubectl create namespace $NS || true
}

function provision_persistent_volume()
{
  local orgnumber=$1
  local pv_config=/tmp/msp-pv-config.yaml

  echo "Provisioning volume storage for Org ${orgnumber}"
  cat ../config/org/msp-pv-template.yaml |
    sed "s|{{ORG_NUMBER}}|${orgnumber}|" > ${pv_config}

  kubectl create -f ${pv_config} || true
}

function claim_persistant_volume()
{
  local orgnumber=$1
  local pvc_config=/tmp/msp-pvc-config.yaml

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

  #local org_config=/tmp/org-admin-cli.yaml

  for ((i=0; i<${orgcount}; i++))
  do
    local dir=/tmp/org${i}
    mkdir -p ${dir}
    local caconfig=${dir}/fabric-ca-server-config.yaml
    echo "Creating fabric CA server config for org ${i}"
    cat ../config/org/fabric-ca-server-config-template.yaml |
      sed "s|{{ORG_NUMBER}}|${i}|" > ${caconfig}
    
    # echo "Creating fabric config map for org ${i}"
    # cat ../config/org/admin-cli-template.yaml |
    #   sed "s|{{ORG_NUMBER}}|${i}|" > ${org_config}

    # kubectl -n $NS delete configmap org${i}-config || true
    # kubectl -n $NS create configmap org${i}-config --from-file=${org_config}
    kubectl -n $NS delete configmap org${i}-config || true
    kubectl -n $NS create configmap org${i}-config --from-file=${dir}
  done
}

function init_tls_cert_issuers()
{
  echo "Initializing Root TLS certificate Issuers"

  # Create a self-signing certificate issuer / root TLS certificate for the blockchain.
  # TODO : Bring-Your-Own-Key - allow the network bootstrap to read an optional ECDSA key pair for the TLS trust root CA.
  kubectl -n $NS apply -f ../config/root-tls-cert-issuer.yaml
  kubectl -n $NS wait --timeout=30s --for=condition=Ready issuer/root-tls-cert-issuer

  echo "Creating TLS cert issuer for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    local issuer_config=/tmp/tls-cert-issuer.yaml
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

  cat ${yaml} \
    | sed 's,{{ORG_NUMBER}},'${number}',g' \
    | sed 's,{{FABRIC_CONTAINER_REGISTRY}},'${FABRIC_CONTAINER_REGISTRY}',g' \
    | sed 's,{{FABRIC_CA_VERSION}},'${FABRIC_CA_VERSION}',g' \
    | kubectl -n $NS apply -f -
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
    local org=$i
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
    # echo "Creating fabric config map for org ${i}"
    # cat ../config/org_template.yaml |
    #   sed "s|\${number}|${i}|" > ${org_config}
    ORG_NUMBER=$i

    cat enroll_msp_with_ca_client.sh |
      sed "s|{{ORG_NUMBER}}|${i}|g" | 
      exec kubectl -n $NS exec deploy org${i}-ca -i -- /bin/sh
  done
}

function launch() {
  local yaml=$1
  local orgnumber=$2
  local orderernumber=$3
  cat ${yaml} \
    | sed 's,{{ORG_NUMBER}},'${orgnumber}',g' \
    | sed 's,{{ORDERER_NUMBER}},'${orderernumber}',g' \
    | sed 's,{{FABRIC_CONTAINER_REGISTRY}},'${FABRIC_CONTAINER_REGISTRY}',g' \
    | sed 's,{{FABRIC_VERSION}},'${FABRIC_VERSION}',g' \
    | kubectl -n $NS apply -f -
}

function launch_orderers() {
  local orgcount=$1
  local orderercount=$2
  echo "Launching ${orderercount} orderer(s) for each of ${orgcount} org(s)"

  for ((i=0; i<${orgcount}; i++))
  do
    for ((j=1; j<=${orderercount}; j++))
    do
      launch ../config/org/orderer-template.yaml ${i} ${j}
      kubectl -n $NS rollout status deploy/org${i}-orderer${j}
    done
  done
}

function create_msp() {
  local orgcount=$1
  shift
  local orderercount=$1

  init_namespace
  init_storage_volumes $orgcount
  load_org_config $orgcount
  init_tls_cert_issuers
  launch_ECert_CAs $orgcount
  enroll_bootstrap_ECert_CA_users $orgcount
  create_local_MSPs $orgcount
  launch_orderers $orgcount $orderercount
  # launch_peers

  # extract_orderer_tls_certs
}

function purge_storage_volumes() {
  kubectl delete pv --all
}

function purge_storage_volume_claims() {
  kubectl delete pvc --all
}
