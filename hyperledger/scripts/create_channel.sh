#!/bin/sh

CHANNEL_TMP_DIR=/tmp/channel

function launch_admin_clis() {
  echo "Launching admin CLIs"

  for ((i=0; i<${orgcount}; i++))
  do
    local admin_cli_config=$CHANNEL_TMP_DIR/org${i}-admin-cli.template.yaml

    cat ../config/org/admin-cli-template.yaml \
    | sed 's,{{ORG_NUMBER}},'${i}',g' \
    | sed 's,{{FABRIC_CONTAINER_REGISTRY}},'${FABRIC_CONTAINER_REGISTRY}',g' \
    | sed 's,{{FABRIC_VERSION}},'${FABRIC_VERSION}',g' > ${admin_cli_config}

    cat ${admin_cli_config} | kubectl -n $NS apply -f -

    kubectl -n $NS rollout status deploy/org${i}-admin-cli
  done
}

function aggregate() {
  echo "Aggregating channel MSP"

  local orgcount=$1

  rm -rf $CHANNEL_TMP_DIR/build/msp/
  mkdir -p $CHANNEL_TMP_DIR/build/msp/

  for ((i=0; i<${orgcount}; i++))
  do
    kubectl -n $NS exec deploy/org${i}-ca -- tar zcvf - -C /var/hyperledger/fabric organizations/ordererOrganizations/org${i}.example.com/msp > $CHANNEL_TMP_DIR/build/msp/msp-org${i}.example.com.tgz
  done

  kubectl -n $NS delete configmap msp-config || true
  kubectl -n $NS create configmap msp-config --from-file=$CHANNEL_TMP_DIR/build/msp/
}

function create_channel_for_org() {
  local org=$1
  local org_type=$2
  local ecert_ca=${org}-ca

  echo 'set -x

  mkdir -p /var/hyperledger/fabric/organizations/'${org_type}'Organizations/'${org}'.example.com/msp/cacerts
  cp \
  $FABRIC_CA_CLIENT_HOME/'${ecert_ca}'/rcaadmin/msp/cacerts/'${ecert_ca}'.pem \
  /var/hyperledger/fabric/organizations/'${org_type}'Organizations/'${org}'.example.com/msp/cacerts

  mkdir -p /var/hyperledger/fabric/organizations/'${org_type}'Organizations/'${org}'.example.com/msp/tlscacerts
  cp \
  /var/hyperledger/fabric/config/tls/ca.crt \
  /var/hyperledger/fabric/organizations/'${org_type}'Organizations/'${org}'.example.com/msp/tlscacerts/'${org}'-tls-ca.pem

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/'${ecert_ca}'.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/'${ecert_ca}'.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/'${ecert_ca}'.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/'${ecert_ca}'.pem
    OrganizationalUnitIdentifier: orderer "> /var/hyperledger/fabric/organizations/'${org_type}'Organizations/'${org}'.example.com/msp/config.yaml
    
  ' | exec kubectl -n $NS exec deploy/${ecert_ca} -i -- /bin/sh
}

# TODO: Needs to be genericized
function create_genesis_block() {
  echo "Creating channel \"${PRIMARY_CHANNEL_NAME}\""

  echo 'set -x
  configtxgen -profile TwoOrgsApplicationGenesis -channelID '${PRIMARY_CHANNEL_NAME}' -outputBlock genesis_block.pb
  # configtxgen -inspectBlock genesis_block.pb
  
  osnadmin channel join --orderer-address org0-orderer1:9443 --channelID '${PRIMARY_CHANNEL_NAME}' --config-block genesis_block.pb
  osnadmin channel join --orderer-address org0-orderer2:9443 --channelID '${PRIMARY_CHANNEL_NAME}' --config-block genesis_block.pb
  osnadmin channel join --orderer-address org0-orderer3:9443 --channelID '${PRIMARY_CHANNEL_NAME}' --config-block genesis_block.pb
  
  ' | exec kubectl -n $NS exec deploy/org0-admin-cli -i -- /bin/bash
  
  sleep 10
}

function join_org_peers()
{
  local org=$1
  echo "Joining ${org} peers to channel \"${PRIMARY_CHANNEL_NAME}\""

  echo 'set -x
    # Fetch the genesis block from an orderer
    peer channel \
      fetch oldest \
      genesis_block.pb \
      -c '${PRIMARY_CHANNEL_NAME}' \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem

    # Join peer1 to the channel.
    CORE_PEER_ADDRESS='${org}'-peer1:7051 \
    peer channel \
      join \
      -b genesis_block.pb \
      -o org0-orderer1:6050 \
      --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
    ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -i -- /bin/bash
}

function channel_init()
{
  orgcount=$1

  create_channel_for_org org0 orderer
  create_channel_for_org org0 peer
  aggregate $orgcount
  launch_admin_clis $orgcount

  create_genesis_block $orgcount
  #join_org_peers org0
  join_org_peers org1
  join_org_peers org2
}
