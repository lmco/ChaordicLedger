#/bin/sh
function log() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now] $1"
}

# Create a random file and upload it.
function createAndUploadRandomFile() {
  now=`date -u +"%Y%m%dT%H%M%SZ"`
  randomFile=randomArtifact_${now}.bin
  head -c 1KiB /dev/urandom > $randomFile
  curl -X POST -F "upfile=@${randomFile}" --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' 'http://localhost:8080/v1/artifact'
  sleep 1
  log "Uploaded ${randomFile}"
}

# Get current graph state
currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $currentGraphState | jq

for i in {1..10}
do
  log "Creating File ${i}"
  createAndUploadRandomFile
done

# Get current graph state
currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $currentGraphState | jq

# Get all known artifacts.
allArtifacts=$(curl -X GET "http://localhost:8080/v1/artifacts/all" -H "accept: */*" | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $allArtifacts | jq

ipfsNames=$(echo $allArtifacts | jq .[].IPFSName | sed "s|\"||g")

# Create relationships between each file
for a in $ipfsNames
do
  for b in $ipfsNames
  do
    if [ a != b ]
    then
      echo "Relating ${a} to ${b}"

      curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "nodeida": "'${a}'",
        "nodeidb": "'${b}'"
      }' 'http://localhost:8080/v1/relationships/createRelationship'
    fi
  done
done

currentGraphState=$(curl -X GET --header 'Accept: application/json' 'http://localhost:8080/v1/relationships' | jq .result | sed "s|\\\\n||g" | cut -c2- | rev | cut -c2- | rev | sed 's|\\"|"|g')
echo $currentGraphState | jq

log "Done"
