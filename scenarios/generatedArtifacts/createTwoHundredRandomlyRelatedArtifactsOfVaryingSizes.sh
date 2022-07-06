#/bin/sh
. ${ROOT_DIR}/scenarios/testenv.sh
SCENARIO_NAME="Create Two Hundred Randomly-Related Artifacts of Varying Sizes"
setTestOutdir

FILE_COUNT_TO_GENERATE=200
RANDOM_RANGE=50

graphsdir=$TEST_OUT_DIR/graphs
filesdir=$TEST_OUT_DIR/files

getGraphState

ipfsNames=()

testlog "Generating ${FILE_COUNT_TO_GENERATE} file(s)"
for i in $(seq 1 $FILE_COUNT_TO_GENERATE)
do
  randomSize=$(( ( RANDOM % 25 )  + 1 ))
  createAndUploadRandomFile ${i} $filesdir "${randomSize}KiB"
  ipfsName=$(echo $UPLOAD_RESULT | jq .result.result.IPFSName | tr -d '"')
  testlog "IPFS name for random file ${i} is ${ipfsName}"
  ipfsNames+=($ipfsName)
done

getGraphState

# Create relationships between each file
# Allow an artifact to relates to itself to demonstrate support for that case.
url="${API_ROOT_URL}/relationships/createRelationship"
relationshipCount=0
for a in "${ipfsNames[@]}"
do
  for b in "${ipfsNames[@]}"
  do
    randomNumber=$(( ( RANDOM % $RANDOM_RANGE )  + 1 ))
    if [ "$randomNumber" == "1" ]
    then
      data='{ "nodeida": "'${a}'", "nodeidb": "'${b}'"}'
      testlog "Relationship $relationshipCount: Relating artifact \"${a}\" to artifact \"${b}\" by posting ${data} to $url"
      result=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "${data}" "${url}")
      testlog $(echo $result | tr -d '[:space:]')
      relationshipCount=$((relationshipCount+1))
    else
      testlog "NOT relating artifact \"${a}\" to artifact \"${b}\""
    fi
  done
done

getGraphState

testlog "Created $relationshipCount relationship(s)"

testlog "Generated files are in $filesdir"
ls -rotl $filesdir

generateRelationshipGraph $graphsdir

testComplete
