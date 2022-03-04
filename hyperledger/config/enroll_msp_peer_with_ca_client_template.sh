set -x
export FABRIC_CA_CLIENT_HOME=/var/hyperledger/fabric-ca-client
export FABRIC_CA_CLIENT_TLS_CERTFILES=/var/hyperledger/fabric/config/tls/ca.crt

# Each identity in the network needs a registration and enrollment.
fabric-ca-client register --id.name org${ORG_NUMBER}-peer${PEER_NUMBER} --id.secret peerpw --id.type peer --url https://org${ORG_NUMBER}-ca --mspdir $FABRIC_CA_CLIENT_HOME/org${ORG_NUMBER}-ca/rcaadmin/msp
fabric-ca-client enroll --url https://org${ORG_NUMBER}-peer${PEER_NUMBER}:peerpw@org${ORG_NUMBER}-ca --csr.hosts localhost,org${ORG_NUMBER}-peer${PEER_NUMBER},org${ORG_NUMBER}-peer-gateway-svc --mspdir /var/hyperledger/fabric/organizations/peerOrganizations/org${ORG_NUMBER}.example.com/peers/org${ORG_NUMBER}-peer${PEER_NUMBER}.org${ORG_NUMBER}.example.com/msp

cp /var/hyperledger/fabric/organizations/peerOrganizations/org${ORG_NUMBER}.example.com/users/Admin@org${ORG_NUMBER}.example.com/msp/keystore/*_sk /var/hyperledger/fabric/organizations/peerOrganizations/org${ORG_NUMBER}.example.com/users/Admin@org${ORG_NUMBER}.example.com/msp/keystore/server.key

# Create local MSP config.yaml
echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/org${ORG_NUMBER}-ca.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/org${ORG_NUMBER}-ca.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/org${ORG_NUMBER}-ca.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/org${ORG_NUMBER}-ca.pem
    OrganizationalUnitIdentifier: orderer" > /var/hyperledger/fabric/organizations/peerOrganizations/org${ORG_NUMBER}.example.com/peers/org${ORG_NUMBER}-peer${PEER_NUMBER}.org${ORG_NUMBER}.example.com/msp/config.yaml

# Hack
# cp /var/hyperledger/fabric/organizations/peerOrganizations/org1.example.com/peers/org1-peer1.org1.example.com/msp/config.yaml /var/hyperledger/fabric/organizations/peerOrganizations/org1.example.com/peers/org1-peer2.org1.example.com/msp/config.yaml
# cp /var/hyperledger/fabric/organizations/peerOrganizations/org1.example.com/peers/org1-peer1.org1.example.com/msp/config.yaml /var/hyperledger/fabric/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml
