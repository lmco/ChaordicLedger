#/bin/sh
set -e

function orchestratorLog() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo -e "[$now | Orchestrator | INFO] $1"
}

orchestratorLog "Orchestrator Started"

wait=30
orchestratorLog "Waiting ${wait} seconds to start tests"
sleep $wait

orchestratorLog "Commencing tests"

export ROOT_DIR=$(pwd)

pushd scenarios

./generatedArtifacts/createOneArtifact.sh

pushd industrial/gpsExample
 ./gpsExample.sh
popd

./generatedArtifacts/createTenRandomlyRelatedArtifacts.sh
./generatedArtifacts/createTwentyRandomlyRelatedArtifacts.sh
./generatedArtifacts/createOneHundredRandomlyRelatedArtifacts.sh
./generatedArtifacts/createTwoHundredRandomlyRelatedArtifactsOfVaryingSizes.sh
./generatedArtifacts/createOneThousandUnrelatedArtifactsOfFixedSize.sh
./generatedArtifacts/createFiveHundredRandomlyRelatedArtifactsOfVaryingSizes.sh

#./testCleanup.sh

popd

orchestratorLog "Scenario execution complete."

#orchestratorLog "Retrieving all blocks from the blockchain."
#./getAllBlocks.sh

orchestratorLog "Done."
