set -x
export FABRIC_CA_CLIENT_HOME=/var/hyperledger/fabric-ca-client
export FABRIC_CA_CLIENT_TLS_CERTFILES=/var/hyperledger/fabric/config/tls/ca.crt
# Each identity in the network needs a registration and enrollment.
fabric-ca-client register --id.name org{{ORG_NUMBER}}-orderer1 --id.secret ordererpw --id.type orderer --url https://org{{ORG_NUMBER}}-ca --mspdir $FABRIC_CA_CLIENT_HOME/org{{ORG_NUMBER}}-ca/rcaadmin/msp
