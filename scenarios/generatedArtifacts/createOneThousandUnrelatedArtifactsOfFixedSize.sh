#/bin/sh
. ${ROOT_DIR}/scenarios/testenv.sh
SCENARIO_NAME="Create One Thousand Unrelated Artifacts of Fixed Size"
setTestOutdir

FILE_COUNT_TO_GENERATE=1000

graphsdir=$TEST_OUT_DIR/graphs
filesdir=$TEST_OUT_DIR/files

getGraphState

ipfsNames=()

testlog "Generating ${FILE_COUNT_TO_GENERATE} file(s)"
for i in $(seq 1 $FILE_COUNT_TO_GENERATE)
do
  size=10
  createAndUploadRandomFile ${i} $filesdir "${size}KiB"
  ipfsName=$(echo $UPLOAD_RESULT | jq .result.result.IPFSName | tr -d '"')
  testlog "IPFS name for random file ${i} is ${ipfsName}"
  ipfsNames+=($ipfsName)
done

getGraphState

testlog "Generated files are in $filesdir"
ls -rotl $filesdir

generateRelationshipGraph $graphsdir

testComplete
