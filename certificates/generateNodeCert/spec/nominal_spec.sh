#!/bin/sh

Describe 'Node Certificate Generation'
  ROOT_PASSPHRASE="something"
  ROOT_CA_CERT_FILE_NAME="rootCACert.pem"
  ROOT_CA_PRIVATE_KEYFILE_NAME="rootCA.key"
  ROOT_PASSPHRASE="testRootCAPhrase"
  ROOT_RESULTS_FILE_NAME="rootCAResults.json"
  ROOT_TEMP_DIR="/tmp/nodeTestSupport"
  ROOT_COUNTRY_CODE="US"
  ROOT_STATE="Alaska"
  ROOT_LOCATION="Anchorage"
  ROOT_ORGANIZATION="Brotherhood of Steel"
  ROOT_ORGANIZATIONAL_UNIT="Scribes"
  ROOT_COMMON_NAME="High Elder"

  NODE_PASSPHRASE="somethingElse"

  setup() { 
    mkdir -p $ROOT_TEMP_DIR
    ../../generateRootCA/bin/generateRootCA.sh -f "$ROOT_RESULTS_FILE_NAME" -p "$ROOT_PASSPHRASE" -o "$ROOT_TEMP_DIR" -c "$ROOT_COUNTRY_CODE" -s "$ROOT_STATE" -l "$ROOT_LOCATION" -r "$ROOT_ORGANIZATION" -u "$ROOT_ORGANIZATIONAL_UNIT" -n "$ROOT_COMMON_NAME" 1>/dev/null 2>/dev/null
  }
  
  cleanup() {
    rm -rf $ROOT_TEMP_DIR
  }

  BeforeAll 'setup'
  AfterAll 'cleanup'

It 'generates a node certificate file and private key file with no passphrase'
    NODE_OUTPUT_DIR="/tmp/nodetest42"
    NODE_RESULTS_FILE_NAME="nodeResults01234.json"
    NODE_COUNTRY_CODE="US"
    NODE_STATE="Colorado"
    NODE_LOCATION="Denver"
    NODE_ORGANIZATION="Lockheed Martin Corporation"
    NODE_ORGANIZATIONAL_UNIT="Space"
    NODE_COMMON_NAME="ChaordicLedger node"

    When run script ../bin/generateNodeCert.sh -f "$NODE_RESULTS_FILE_NAME" -a "$ROOT_TEMP_DIR/$ROOT_CA_CERT_FILE_NAME" -b "$ROOT_TEMP_DIR/$ROOT_CA_PRIVATE_KEYFILE_NAME" -d "$ROOT_PASSPHRASE" -o "$NODE_OUTPUT_DIR" -c "$NODE_COUNTRY_CODE" -s "$NODE_STATE" -l "$NODE_LOCATION" -r "$NODE_ORGANIZATION" -u "$NODE_ORGANIZATIONAL_UNIT" -n "$NODE_COMMON_NAME"
    The path $NODE_OUTPUT_DIR should be present
    The path "$NODE_OUTPUT_DIR/$NODE_RESULTS_FILE_NAME" should be present
    The output should be present
    The stderr should be present
    The status should equal 0
    The contents of file "$NODE_OUTPUT_DIR/$NODE_RESULTS_FILE_NAME" should equal '{
    "Inputs": {
        "ResultsFileName": "nodeResults01234.json",
        "RootCACertFile": "/tmp/nodeTestSupport/rootCACert.pem",
        "RootCAKeyFile": "/tmp/nodeTestSupport/rootCA.key",
        "RootCAPassphrase": "<MASKED>",
        "NodeCertPassphrase": "<None provided>",
        "OutputDirectory": "/tmp/nodetest42",
        "CountryCode": "US",
        "State": "Colorado",
        "Location": "Denver",
        "Organization": "Lockheed Martin Corporation",
        "OrganizationalUnit": "Space",
        "CommonName": "ChaordicLedger node"
    },
    "Outputs" : {
      "NodePrivateKeyFile" : {
        "Name": "node.key",
        "Type": "PEM"
      },
      "NodeSignedCertificateFile" : {
        "Name": "nodeCert.pem",
        "Type": "PEM"
      },
      "ResultsFile" : {
        "Name": "nodeResults01234.json",
        "Type": "JSON"
      }
    }
}'

    CERTSUBJECT=$(openssl x509 -noout -in /tmp/nodetest42/nodeCert.pem -subject 2>/dev/null)
    The value "$CERTSUBJECT" should equal "subject=C = US, ST = Colorado, L = Denver, O = Lockheed Martin Corporation, OU = Space, CN = ChaordicLedger node"

    # Using this since there's a race condition between evaluation and the use of an AfterRun hook.
    rm -rf $NODE_OUTPUT_DIR
  End

  It 'generates a node certificate file and private key file with a passphrase'
    NODE_OUTPUT_DIR="/tmp/nodetest1"
    NODE_RESULTS_FILE_NAME="nodeResults0.json"
    NODE_COUNTRY_CODE="US"
    NODE_STATE="Colorado"
    NODE_LOCATION="Denver"
    NODE_ORGANIZATION="Lockheed Martin Corporation"
    NODE_ORGANIZATIONAL_UNIT="Space"
    NODE_COMMON_NAME="ChaordicLedger node"

    When run script ../bin/generateNodeCert.sh -f "$NODE_RESULTS_FILE_NAME" -a "$ROOT_TEMP_DIR/$ROOT_CA_CERT_FILE_NAME" -b "$ROOT_TEMP_DIR/$ROOT_CA_PRIVATE_KEYFILE_NAME" -d "$ROOT_PASSPHRASE" -o "$NODE_OUTPUT_DIR" -p "$NODE_PASSPHRASE" -c "$NODE_COUNTRY_CODE" -s "$NODE_STATE" -l "$NODE_LOCATION" -r "$NODE_ORGANIZATION" -u "$NODE_ORGANIZATIONAL_UNIT" -n "$NODE_COMMON_NAME"
    The path $NODE_OUTPUT_DIR should be present
    The path "$NODE_OUTPUT_DIR/$NODE_RESULTS_FILE_NAME" should be present
    The output should be present
    The stderr should be present
    The status should equal 0
    The contents of file "$NODE_OUTPUT_DIR/$NODE_RESULTS_FILE_NAME" should equal '{
    "Inputs": {
        "ResultsFileName": "nodeResults0.json",
        "RootCACertFile": "/tmp/nodeTestSupport/rootCACert.pem",
        "RootCAKeyFile": "/tmp/nodeTestSupport/rootCA.key",
        "RootCAPassphrase": "<MASKED>",
        "NodeCertPassphrase": "<MASKED>",
        "OutputDirectory": "/tmp/nodetest1",
        "CountryCode": "US",
        "State": "Colorado",
        "Location": "Denver",
        "Organization": "Lockheed Martin Corporation",
        "OrganizationalUnit": "Space",
        "CommonName": "ChaordicLedger node"
    },
    "Outputs" : {
      "NodePrivateKeyFile" : {
        "Name": "node.key",
        "Type": "PEM"
      },
      "NodeSignedCertificateFile" : {
        "Name": "nodeCert.pem",
        "Type": "PEM"
      },
      "ResultsFile" : {
        "Name": "nodeResults0.json",
        "Type": "JSON"
      }
    }
}'

    CERTSUBJECT=$(openssl x509 -noout -in /tmp/nodetest1/nodeCert.pem -subject 2>/dev/null)
    The value "$CERTSUBJECT" should equal "subject=C = US, ST = Colorado, L = Denver, O = Lockheed Martin Corporation, OU = Space, CN = ChaordicLedger node"

    # Using this since there's a race condition between evaluation and the use of an AfterRun hook.
    rm -rf $NODE_OUTPUT_DIR
  End
End
