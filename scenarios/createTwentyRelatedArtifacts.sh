#/bin/sh
function log() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now] $1"
}

function getGraphState() {
  # Get current graph state
  currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
  echo $currentGraphState | jq
}

# Create a random file and upload it.
function createAndUploadRandomFile() {
  index=$1
  filesdir=$2
  mkdir -p $filesdir
  now=`date -u +"%Y%m%dT%H%M%SZ"`
  randomFile=$filesdir/randomArtifact${index}_${now}.bin
  head -c 1KiB /dev/urandom > $randomFile
  curl -X POST -F "upfile=@${randomFile}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' 'http://localhost:8080/v1/artifact'
  sleep 1
  log "Uploaded ${randomFile}"
}

outdir=/tmp/chaordicledger/generated
graphsdir=$outdir/graphs
filesdir=$outdir/files

getGraphState

for i in {1..20}
do
  log "Creating File ${i}"
  createAndUploadRandomFile ${i} $filedir
done

getGraphState

# Get all known artifacts.
allArtifacts=$(curl -X GET "http://localhost:8080/v1/artifacts/all" -H "accept: */*" | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $allArtifacts | jq

ipfsNames=$(echo $allArtifacts | jq .[].IPFSName | sed "s|\"||g")

# Create relationships between each file
# Allow an artifact to relates to itself to demonstrate support for that case.
for a in $ipfsNames
do
  for b in $ipfsNames
  do
    echo "Relating ${a} to ${b}"
    curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
      "nodeida": "'${a}'",
      "nodeidb": "'${b}'"
    }' 'http://localhost:8080/v1/relationships/createRelationship'
  done
done

getGraphState

python3 tools/digraphGenerator.py -o $graphsdir
ls -rotl $filesdir
ls -rotl $graphsdir

log "Done"
