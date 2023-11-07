#/bin/sh
. ${ROOT_DIR}/env.sh
API_ROOT_URL="http://localhost:8080/v1"
OUT_DIR=/tmp/chaordicledger/scenarios

function setTestOutdir() {

        export TEST_OUT_DIR=$(echo "$OUT_DIR/${SCENARIO_NAME// /}" | sed "s|-||")
}

function testlog() {
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo -e "[$now | ${SYSTEM_NAME} | \"${SCENARIO_NAME}\" | INFO] $1"
}

function testerr() {
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo -e "[$now | ${SYSTEM_NAME} | \"${SCENARIO_NAME}\" | ERROR] $1"
}

function getGraphState() {
        url="${API_ROOT_URL}/relationships/getRelationshipGraphFile"
        testlog "Getting current graph state from ${url}"
        currentGraphState=$(curl -s -X GET --header 'Accept: application/json' "${url}")
        testlog $(echo $currentGraphState | tr -d '[:space:]')
}

function getAllKnownArtifacts() {
        url="${API_ROOT_URL}/artifacts/listAllArtifacts"
        testlog "Getting all known artifacts from ${url}"
        export allArtifacts=$(curl -s -X GET --header 'Accept: application/json' "${url}")
        testlog $(echo $allArtifacts | jq .result | tr -d '[:space:]')
}

function getIPFSNames() {
        testlog "Getting the IPFS names of all known artifacts."
        export ipfsNames=$(echo $allArtifacts | jq .result | jq .[].IPFSName | sed "s|\"||g")
        oneline=$(echo $ipfsNames | tr '\n\t' ' ')
        testlog "$oneline"
}

function createAndUploadRandomFile() {
        index=$1
        filesdir=$2

        if [ -n "$3" ]; then
                size="$3"
        else
                size="1KiB"
        fi

        url="${API_ROOT_URL}/artifacts/createArtifact"
        testlog "Creating random file number ${index} of size ${size} and uploading it to ${url}."

        mkdir -p $filesdir
        now=$(date -u +"%Y%m%dT%H%M%SZ")
        randomFile=$filesdir/randomArtifact${index}_${now}.bin
        head -c $size /dev/urandom >$randomFile
        export UPLOAD_RESULT=$(curl -s -X POST -F "upfile=@${randomFile}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' "${url}")
        testlog $(echo $UPLOAD_RESULT | tr -d '[:space:]')
        sleep 1
        testlog "Uploaded random local file \"${randomFile}\" of size $size."
}

function generateRelationshipGraph() {
        local graphOutputDir=$1
        local filenamePrefix=$(date -u +"%Y%m%d%H%M%S_")

        testlog "Generating relationship DOT file to ${graphOutputDir} with prefix ${filenamePrefix}"
        python3 ${ROOT_DIR}/tools/digraphGenerator.py -t "${SCENARIO_NAME}" -p ${filenamePrefix} -o ${graphOutputDir}

        testlog "Generated relationship DOT file is in $graphOutputDir"
        ls -rotl $graphOutputDir
}

function testComplete() {
        testlog "Done executing test scenario \"${SCENARIO_NAME}\"."
}
