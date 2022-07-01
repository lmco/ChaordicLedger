#/bin/sh
. ${ROOT_DIR}/scenarios/testenv.sh
SCENARIO_NAME="Industry Example - GPS Time Format"
FILE_COUNT_TO_GENERATE=1
setTestOutdir

graphsdir=$TEST_OUT_DIR/graphs

getGraphState

python3 ../inputProcessor.py -i ./inputs

getAllKnownArtifacts

getGraphState

getIPFSNames

generateRelationshipGraph $graphsdir

testComplete
