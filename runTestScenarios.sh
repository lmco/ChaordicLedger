#/bin/sh
set -e

function orchestratorLog() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo -e "[$now | Orchestrator | INFO] $1"
}

function waitForSeconds() {
  wait=$1
  orchestratorLog "Waiting ${wait} seconds"
  sleep $wait
}

orchestratorLog "Orchestrator Started"

#waitForSeconds 30

orchestratorLog "Commencing tests"

export ROOT_DIR=$(pwd)

pushd scenarios

./generatedArtifacts/createOneArtifact.sh
waitForSeconds 30

pushd industrial/gpsExample
 ./gpsExample.sh
popd
waitForSeconds 30

pushd industrial/salesSystem
 ./salesSystem.sh
popd
waitForSeconds 30

./generatedArtifacts/createTenRandomlyRelatedArtifacts.sh
waitForSeconds 30

./generatedArtifacts/createTwentyRandomlyRelatedArtifacts.sh
waitForSeconds 30

./generatedArtifacts/createOneHundredRandomlyRelatedArtifacts.sh
waitForSeconds 30

./generatedArtifacts/createTwoHundredRandomlyRelatedArtifactsOfVaryingSizes.sh
waitForSeconds 30

./generatedArtifacts/createOneThousandUnrelatedArtifactsOfFixedSize.sh
waitForSeconds 30

./generatedArtifacts/createFiveHundredRandomlyRelatedArtifactsOfVaryingSizes.sh
waitForSeconds 30

#./testCleanup.sh

popd

orchestratorLog "Scenario execution complete."

#orchestratorLog "Retrieving all blocks from the blockchain."
#./getAllBlocks.sh

orchestratorLog "Done."
