#/bin/sh
. ../env.sh
API_ROOT_URL="http://localhost:8080/v1"
OUT_DIR=/tmp/chaordicledger/generated

function setTestOutdir() {
  export TEST_OUT_DIR="$OUT_DIR/${SCENARIO_NAME// /}"
}

function testlog() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo -e "[$now | ${SYSTEM_NAME} | \"${SCENARIO_NAME}\" | INFO] $1"
}

function testerr() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo -e "[$now | ${SYSTEM_NAME} | \"${SCENARIO_NAME}\" | ERROR] $1"
}

function getGraphState() {
  url="${API_ROOT_URL}/relationships/getRelationshipGraph"
  testlog "Getting current graph state from ${url}"
  currentGraphState=$(curl -s -X GET --header 'Accept: application/json' "${url}")
  testlog $(echo $currentGraphState | tr -d '[:space:]')
}

function getAllKnownArtifacts() {
  url="${API_ROOT_URL}/artifacts/listAllArtifacts"
  testlog "Getting all known artifacts from ${url}"
  export allArtifacts=$(curl -s -X GET --header 'Accept: application/json' "${url}")
  testlog $(echo $allArtifacts | tr -d '[:space:]')
}

function createAndUploadRandomFile() {
  index=$1
  filesdir=$2
  size="1KiB"
  url="${API_ROOT_URL}/artifact"
  testlog "Creating random file number ${index} and uploading it to ${url}."

  mkdir -p $filesdir
  now=`date -u +"%Y%m%dT%H%M%SZ"`
  randomFile=$filesdir/randomArtifact${index}_${now}.bin
  head -c $size /dev/urandom > $randomFile
  result=$(curl -s -X POST -F "upfile=@${randomFile}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' "${url}")
  testlog $(echo $result | tr -d '[:space:]')
  sleep 1
  testlog "Uploaded random local file \"${randomFile}\" of size $size."
}

function generateRelationshipGraph() {
  local graphOutputDir=$1
  local filenamePrefix=$(date -u +"%Y%m%d%H%M%S_")

  testlog "Generating relationship DOT file to ${graphOutputDir} with prefix ${filenamePrefix}"
  python3 ${ROOT_DIR}/tools/digraphGenerator.py -t "${SCENARIO_NAME}" -p ${filenamePrefix} -o ${graphOutputDir}

  testlog "Generated relationship DOT file is in $graphsdir"
  ls -rotl $graphsdir
}

function testComplete() {
  testlog "Done executing test scenario \"${SCENARIO_NAME}\"."
}
