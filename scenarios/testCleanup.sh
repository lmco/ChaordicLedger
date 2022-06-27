#/bin/sh
. testenv.sh
SCENARIO_NAME="Cleanup"
setTestOutdir

testlog "Resetting relationship data."
curl -X DELETE --header 'Accept: application/json' "${API_ROOT_URL}/system/resetRelationships"

sleep 5

testlog "Resetting artifact storage."
curl -X DELETE --header 'Accept: application/json' "${API_ROOT_URL}/system/resetArtifacts"

sleep 5

testlog "Test cleanup complete."
