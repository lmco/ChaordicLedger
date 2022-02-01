#!/bin/sh
# Follows Shell Style Guide at https://google.github.io/styleguide/shellguide.html.
# Recommended linting by ShellCheck at from https://github.com/koalaman/shellcheck.
# Possible testing via ShellSpec https://shellspec.info.
# Useful references:
#   https://datacenteroverlords.com/2012/03/01/creating-your-own-ssl-certificate-authority/
#   https://www.assertnotmagic.com/2019/03/08/bash-advanced-arguments
set -e

ROOT_CA_CERT_FILE=""
ROOT_CA_KEY_FILE=""
ROOT_CA_PASSPHRASE=""
PHRASE=""
OUTDIR=""
COUNTRY_CODE=""
STATE=""
LOCATION=""
ORGANIZATION=""
ORGANIZATIONAL_UNIT=""
COMMON_NAME=""
RESULTS_FILE_NAME=""

print_usage() {
  printf "Usage: %s
    [-h]
    -f <Results file name to appear in output directory>
    -a <RootCACertFile>
    -b <RootCAKeyFile>
    -d <RootCAPassphrase>
    -p <NodeCertPassphrase>
    -o <Output directory>
    -c <ISO 3166-2 two-letter country code>
    -s <State>
    -l <Location>
    -r <Organization>
    -u <Organizational Unit>
    -n <Common Name>\n" "$0"
}

check_arg() {
  arg=$1
  argname=$2
  errcode=$3
  show=$4

  if [ "$arg" = "" ]; then
    if [ "$errcode" -eq 0 ]; then
      echo "WARN: $argname was not provided."
    else
      echo "ERROR: $argname must be provided"
      exit "$errcode"
    fi
  else
    if [ "$show" = "true" ]; then
      echo "$argname is \"$arg\""
    else
      echo "Not showing value for argument \"$argname\""
    fi
  fi
}

if [ $# -eq 0 ]; then
  print_usage
  exit 1
fi

while getopts "ha:b:d:p:o:f:c:s:l:r:u:n:" option; do
  case $option in
    h) # display help
      print_usage
      exit 2;;
    a) # Root CA Certificate File
      ROOT_CA_CERT_FILE=$OPTARG;;
    b) # Root CA Key file
      ROOT_CA_KEY_FILE=$OPTARG;;
    d) # Root CA Passphrase
      ROOT_CA_PASSPHRASE=$OPTARG;;
    p) # passphrase for root CA key
      PHRASE=$OPTARG;;
    o) # Provide an output directory
      OUTDIR=$OPTARG;;
    f) # Results File Name
      RESULTS_FILE_NAME=$OPTARG;;
    c) # ISO country code (/C)
      COUNTRY_CODE=$OPTARG;;
    s) # State (/S)
      STATE=$OPTARG;;
    l) # Location (/L)
      LOCATION=$OPTARG;;
    r) # Organization (/O)
      ORGANIZATION=$OPTARG;;
    u) # Organization Unit (/OU)
      ORGANIZATIONAL_UNIT=$OPTARG;;
    n) # Common Name (/CN)
      COMMON_NAME=$OPTARG;;
   \?) # Invalid option
      echo "Error: Invalid option"
      print_usage
      exit 3;;
  esac
done

readonly ROOT_CA_CERT_FILE
readonly ROOT_CA_KEY_FILE
readonly ROOT_CA_PASSPHRASE
readonly RESULTS_FILE_NAME
readonly PHRASE
readonly OUTDIR
readonly COUNTRY_CODE
readonly STATE
readonly LOCATION
readonly ORGANIZATION
readonly ORGANIZATIONAL_UNIT
readonly COMMON_NAME

#check_arg "$PHRASE" "passphrase" 0 "false"
check_arg "$ROOT_CA_CERT_FILE" "RootCACertFile" 12 "true"
check_arg "$ROOT_CA_KEY_FILE" "RootCAKeyFile" 13 "true"
check_arg "$ROOT_CA_PASSPHRASE" "RootCAPassphrase" 14 "false"
check_arg "$RESULTS_FILE_NAME" "ResultsFileName" 4 "true"
check_arg "$OUTDIR" "OutputDirectory" 5 "true"
check_arg "$COUNTRY_CODE" "CountryCode" 6 "true"
check_arg "$STATE" "State" 7 "true"
check_arg "$LOCATION" "Location" 8 "true"
check_arg "$ORGANIZATION" "Organization" 9 "true"
check_arg "$ORGANIZATIONAL_UNIT" "OrganizationalUnit" 10 "true"
check_arg "$COMMON_NAME" "CommonName" 11 "true"

# Check if openssl is available.
if ! result=$(which openssl); then
  echo "ERROR: The openssl tool must be installed ($result)".
  exit 100
else
  echo "The openssl tool is available."
fi

readonly RESULTS_FILE_PATH="$OUTDIR/$RESULTS_FILE_NAME"

mkdir -p "$OUTDIR"

readonly KEYFILE_NAME="node.key"
readonly CERT_SIGN_REQUEST_FILE_NAME="node.csr"
readonly CERTFILE_NAME="nodeCert.pem"
readonly KEYFILE_PATH="$OUTDIR/$KEYFILE_NAME"
readonly CERT_SIGN_REQUEST_FILE_PATH="$OUTDIR/$CERT_SIGN_REQUEST_FILE_NAME"
readonly CERTFILE_PATH="$OUTDIR/$CERTFILE_NAME"
readonly OPENSSL_OUTPUT_TYPE="PEM"
readonly KEYSIZE_IN_BITS="4096"

if [ "$PHRASE" = "" ]; then
  echo "WARN: Empty passphrase provided for node private key."
  openssl genrsa -out "$KEYFILE_PATH" "$KEYSIZE_IN_BITS"
else
  openssl genrsa -des3 -passout "pass:$PHRASE" -out "$KEYFILE_PATH" "$KEYSIZE_IN_BITS"
fi

openssl req -batch -verbose -passin "pass:$PHRASE" -new -nodes -key "$KEYFILE_PATH" -sha512 -days 1024 -out "$CERT_SIGN_REQUEST_FILE_PATH" -subj "/C=$COUNTRY_CODE/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME"

openssl x509 -req -in "$CERT_SIGN_REQUEST_FILE_PATH" -passin "pass:$ROOT_CA_PASSPHRASE" -CA "$ROOT_CA_CERT_FILE" -CAkey "$ROOT_CA_KEY_FILE" -CAcreateserial -out "$CERTFILE_PATH" -days 500 -sha512

openssl x509 -text -noout -in "$CERTFILE_PATH"

ROOT_PHRASE_TO_OUTPUT="<MASKED>"
if [ "$ROOT_CA_PASSPHRASE" = "" ]; then
  ROOT_PHRASE_TO_OUTPUT="<None provided>"
fi

PHRASE_TO_OUTPUT="<MASKED>"
if [ "$PHRASE" = "" ]; then
  PHRASE_TO_OUTPUT="<None provided>"
fi

{
  echo "{"
  echo "    \"Inputs\": {"
  echo "        \"ResultsFileName\": \"$RESULTS_FILE_NAME\","
  echo "        \"RootCACertFile\": \"$ROOT_CA_CERT_FILE\","
  echo "        \"RootCAKeyFile\": \"$ROOT_CA_KEY_FILE\","
  echo "        \"RootCAPassphrase\": \"$ROOT_PHRASE_TO_OUTPUT\","
  echo "        \"NodeCertPassphrase\": \"$PHRASE_TO_OUTPUT\","
  echo "        \"OutputDirectory\": \"$OUTDIR\","
  echo "        \"CountryCode\": \"$COUNTRY_CODE\","
  echo "        \"State\": \"$STATE\","
  echo "        \"Location\": \"$LOCATION\","
  echo "        \"Organization\": \"$ORGANIZATION\","
  echo "        \"OrganizationalUnit\": \"$ORGANIZATIONAL_UNIT\","
  echo "        \"CommonName\": \"$COMMON_NAME\""
  echo "    },"
  echo "    \"Outputs\" : {"
  echo "      \"NodePrivateKeyFile\" : {"
  echo "        \"Name\": \"$KEYFILE_NAME\","
  echo "        \"Type\": \"$OPENSSL_OUTPUT_TYPE\""
  echo "      },"
  echo "      \"NodeSignedCertificateFile\" : {"
  echo "        \"Name\": \"$CERTFILE_NAME\","
  echo "        \"Type\": \"$OPENSSL_OUTPUT_TYPE\""
  echo "      },"
  echo "      \"ResultsFile\" : {"
  echo "        \"Name\": \"$RESULTS_FILE_NAME\","
  echo "        \"Type\": \"JSON\""
  echo "      }"
  echo "    }"
  echo "}"
} > "$RESULTS_FILE_PATH"
