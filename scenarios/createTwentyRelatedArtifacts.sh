#/bin/sh
SCENARIO_NAME="Create twenty related artifacts"

function testlog() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now | ${SYSTEM_NAME} | Test Scenaro \"${SCENARIO_NAME}\"] $1"
}

function getGraphState() {
  testlog "Getting current graph state."
  currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
  testlog $(echo $currentGraphState | jq)
}

function createAndUploadRandomFile() {
  index=$1
  filesdir=$2
  size="1KiB"
  testlog "Creating random file number ${index} and uploading it."
  mkdir -p $filesdir
  now=`date -u +"%Y%m%dT%H%M%SZ"`
  randomFile=$filesdir/randomArtifact${index}_${now}.bin
  head -c $size /dev/urandom > $randomFile
  testlog $(curl -X POST -F "upfile=@${randomFile}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' 'http://localhost:8080/v1/artifact')
  sleep 1
  testlog "Uploaded random local file \"${randomFile}\" of size $size."
}

outdir=/tmp/chaordicledger/generated
graphsdir=$outdir/graphs
filesdir=$outdir/files

getGraphState

for i in {1..20}
do
  createAndUploadRandomFile ${i} $filesdir
done

getGraphState

testlog "Getting all known artifacts."
allArtifacts=$(curl -X GET "http://localhost:8080/v1/artifacts/all" -H "accept: */*" | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
testlog $(echo $allArtifacts | jq)

testlog "Getting the IPFS names of all known artifacts."
ipfsNames=$(echo $allArtifacts | jq .[].IPFSName | sed "s|\"||g")
testlog $ipfsNames

# Create relationships between each file
# Allow an artifact to relates to itself to demonstrate support for that case.

#url="http://localhost:8080/v1/relationships/createRelationship"
for a in $ipfsNames
do
  for b in $ipfsNames
  do
    testlog "Relating artifact \"${a}\" to artifact \"${b}\""
    testlog $(curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
      "nodeida": "'${a}'",
      "nodeidb": "'${b}'"
    }' 'http://localhost:8080/v1/relationships/createRelationship')
  done
done

getGraphState

testlog "Generating relationship DOT file to ${graphsdir}"
python3 tools/digraphGenerator.py -o $graphsdir

testlog "Generated files are in $filesdir"
ls -rotl $filesdir

testlog "Generated relationship DOT file is in $graphsdir"
ls -rotl $graphsdir

testlog "Done executing test scenario \"${SCENARIO_NAME}\"."
