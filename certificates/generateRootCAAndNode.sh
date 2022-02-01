#!/bin/sh
# Follows Shell Style Guide at https://google.github.io/styleguide/shellguide.html.
# Recommended linting by ShellCheck at from https://github.com/koalaman/shellcheck.
# Possible testing via ShellSpec https://shellspec.info.
# Useful references:
#   https://datacenteroverlords.com/2012/03/01/creating-your-own-ssl-certificate-authority/
#   https://www.assertnotmagic.com/2019/03/08/bash-advanced-arguments
set -e

export PATH=.:"$PATH"

# Check if jq is available.
if ! result=$(which jq); then
  echo "jq not available ($result). Downloading..."
  wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
  chmod +x jq
else
  echo "The jq tool is available."
fi

readonly ROOT_PASSPHRASE="temp"
readonly NODE_PASSPHRASE="something"

readonly OUTPUT_DIR="tmp"
readonly ROOT_RESULTS_FILE_NAME="rootCAResults.json"
readonly COUNTRY_CODE="US"
readonly STATE="PA"
readonly LOCATION="King of Prussia"
readonly ORGANIZATION="Lockheed Martin Corporation"
readonly ORGANIZATIONAL_UNIT="Space"
readonly ROOT_COMMON_NAME="ChaordicLedger Root CA"
readonly NODE_COMMON_NAME="ChaordicLedger Node 1"
readonly NODE_RESULTS_FILE_NAME="nodeResults.json"

./generateRootCA/bin/generateRootCA.sh -f "$ROOT_RESULTS_FILE_NAME" -p "$ROOT_PASSPHRASE" -o "$OUTPUT_DIR" -c "$COUNTRY_CODE" -s "$STATE" -l "$LOCATION" -r "$ORGANIZATION" -u "$ORGANIZATIONAL_UNIT" -n "$ROOT_COMMON_NAME"

readonly ROOT_RESULTS_FILE_PATH="$OUTPUT_DIR/$ROOT_RESULTS_FILE_NAME"

ROOT_CA_PRIVATE_KEYFILE_NAME="$(jq '(.Inputs.OutputDirectory) + "/" + (.Outputs.RootCAPrivateKeyFile.Name)' "$ROOT_RESULTS_FILE_PATH" | sed "s|\"||g")"
ROOT_CA_CERT_FILE_NAME="$(jq '(.Inputs.OutputDirectory) + "/" + (.Outputs.RootCASelfSignedCertificateFile.Name)' "$ROOT_RESULTS_FILE_PATH" | sed "s|\"||g")"

echo "Root Private Keyfile: $ROOT_CA_PRIVATE_KEYFILE_NAME"
echo "Root Certificate file: $ROOT_CA_CERT_FILE_NAME"

./generateNodeCert/bin/generateNodeCert.sh -f "$NODE_RESULTS_FILE_NAME" -a "$ROOT_CA_CERT_FILE_NAME" -b "$ROOT_CA_PRIVATE_KEYFILE_NAME" -d "$ROOT_PASSPHRASE" -o "$OUTPUT_DIR" -p "$NODE_PASSPHRASE" -c "$COUNTRY_CODE" -s "$STATE" -l "$LOCATION" -r "$ORGANIZATION" -u "$ORGANIZATIONAL_UNIT" -n "$NODE_COMMON_NAME"

readonly NODE_RESULTS_FILE_PATH="$OUTPUT_DIR/$NODE_RESULTS_FILE_NAME"

cat "$NODE_RESULTS_FILE_PATH"

NODE_KEYFILE_NAME="$(jq '(.Inputs.OutputDirectory) + "/" + (.Outputs.NodePrivateKeyFile.Name)' "$NODE_RESULTS_FILE_PATH" | sed "s|\"||g")"
NODE_CERT_FILE_NAME="$(jq '(.Inputs.OutputDirectory) + "/" + (.Outputs.NodeSignedCertificateFile.Name)' "$NODE_RESULTS_FILE_PATH" | sed "s|\"||g")"

echo "Node Private Keyfile: $NODE_KEYFILE_NAME"
echo "Node Certificate file: $NODE_CERT_FILE_NAME"
