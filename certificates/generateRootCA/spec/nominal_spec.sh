#!/bin/sh
# TODO: Augment to check the contents of the certificate.

Describe 'Root Certificate Authority (CA) Generation'
  ROOT_PASSPHRASE="temp"

  It 'generates a root CA certificate file and private key file with no passphrase'
    OUTPUT_DIR="/tmp/rootCAtest1"
    ROOT_RESULTS_FILE_NAME="rootCAResults0.json"
    COUNTRY_CODE="US"
    STATE="Colorado"
    LOCATION="Denver"
    ORGANIZATION="Lockheed Martin Corporation"
    ORGANIZATIONAL_UNIT="Space"
    ROOT_COMMON_NAME="ChaordicLedger Root CA"

    When run script ../bin/generateRootCA.sh -f "$ROOT_RESULTS_FILE_NAME" -o "$OUTPUT_DIR" -c "$COUNTRY_CODE" -s "$STATE" -l "$LOCATION" -r "$ORGANIZATION" -u "$ORGANIZATIONAL_UNIT" -n "$ROOT_COMMON_NAME"
    The path $OUTPUT_DIR should be present
    The path "$OUTPUT_DIR/$ROOT_RESULTS_FILE_NAME" should be present
    The output should be present
    The stderr should be present
    The status should equal 0
    The contents of file "$OUTPUT_DIR/$ROOT_RESULTS_FILE_NAME" should equal '{
    "Inputs": {
        "ResultsFileName": "rootCAResults0.json",
        "Passphrase": "<None provided>",
        "OutputDirectory": "/tmp/rootCAtest1",
        "CountryCode": "US",
        "State": "Colorado",
        "Location": "Denver",
        "Organization": "Lockheed Martin Corporation",
        "OrganizationalUnit": "Space",
        "CommonName": "ChaordicLedger Root CA"
    },
    "Outputs" : {
      "RootCAPrivateKeyFile" : {
        "Name": "rootCA.key",
        "Type": "PEM"
      },
      "RootCASelfSignedCertificateFile" : {
        "Name": "rootCACert.pem",
        "Type": "PEM"
      },
      "ResultsFile" : {
        "Name": "rootCAResults0.json",
        "Type": "JSON"
      }
    }
}'

    CERTSUBJECT=$(openssl x509 -noout -in /tmp/rootCAtest1/rootCACert.pem -subject 2>/dev/null)
    The value "$CERTSUBJECT" should equal "subject=C = US, ST = Colorado, L = Denver, O = Lockheed Martin Corporation, OU = Space, CN = ChaordicLedger Root CA"

    # Using this since there's a race condition between evaluation and the use of an AfterRun hook.
    rm -rf $OUTPUT_DIR
  End

  It 'generates a root CA certificate file and private key file with a passphrase'
    OUTPUT_DIR="/tmp/rootCAtest2"
    ROOT_RESULTS_FILE_NAME="rootCAResults15.json"
    COUNTRY_CODE="AU"
    STATE="WA"
    LOCATION="Northbridge"
    ORGANIZATION="Hotels"
    ORGANIZATIONAL_UNIT="Fancy"
    ROOT_COMMON_NAME="Yet another root cert authority"
    
    When run script ../bin/generateRootCA.sh -f "$ROOT_RESULTS_FILE_NAME" -p "$ROOT_PASSPHRASE" -o "$OUTPUT_DIR" -c "$COUNTRY_CODE" -s "$STATE" -l "$LOCATION" -r "$ORGANIZATION" -u "$ORGANIZATIONAL_UNIT" -n "$ROOT_COMMON_NAME"
    The path $OUTPUT_DIR should be present
    The path "$OUTPUT_DIR/$ROOT_RESULTS_FILE_NAME" should be present
    The output should be present
    The stderr should be present
    The status should equal 0
    The contents of file "$OUTPUT_DIR/$ROOT_RESULTS_FILE_NAME" should equal '{
    "Inputs": {
        "ResultsFileName": "rootCAResults15.json",
        "Passphrase": "<MASKED>",
        "OutputDirectory": "/tmp/rootCAtest2",
        "CountryCode": "AU",
        "State": "WA",
        "Location": "Northbridge",
        "Organization": "Hotels",
        "OrganizationalUnit": "Fancy",
        "CommonName": "Yet another root cert authority"
    },
    "Outputs" : {
      "RootCAPrivateKeyFile" : {
        "Name": "rootCA.key",
        "Type": "PEM"
      },
      "RootCASelfSignedCertificateFile" : {
        "Name": "rootCACert.pem",
        "Type": "PEM"
      },
      "ResultsFile" : {
        "Name": "rootCAResults15.json",
        "Type": "JSON"
      }
    }
}'

    CERTSUBJECT=$(openssl x509 -noout -in /tmp/rootCAtest2/rootCACert.pem -subject 2>/dev/null)
    The value "$CERTSUBJECT" should equal "subject=C = AU, ST = WA, L = Northbridge, O = Hotels, OU = Fancy, CN = Yet another root cert authority"

    # Using this since there's a race condition between evaluation and the use of an AfterRun hook.
    rm -rf $OUTPUT_DIR
  End
End
