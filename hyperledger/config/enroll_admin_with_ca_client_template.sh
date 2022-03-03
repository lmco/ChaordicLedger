set -x
export FABRIC_CA_CLIENT_HOME=/var/hyperledger/fabric-ca-client
export FABRIC_CA_CLIENT_TLS_CERTFILES=/var/hyperledger/fabric/config/tls/ca.crt

# Each identity in the network needs a registration and enrollment.
fabric-ca-client register --id.name org{{ORG_NUMBER}}-admin --id.secret org{{ORG_NUMBER}}adminpw  --id.type admin   --url https://org{{ORG_NUMBER}}-ca --mspdir $FABRIC_CA_CLIENT_HOME/org{{ORG_NUMBER}}-ca/rcaadmin/msp --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
fabric-ca-client enroll --url https://org{{ORG_NUMBER}}-admin:org{{ORG_NUMBER}}adminpw@org{{ORG_NUMBER}}-ca --mspdir /var/hyperledger/fabric/organizations/ordererOrganizations/org{{ORG_NUMBER}}.example.com/users/Admin@org{{ORG_NUMBER}}.example.com/msp
