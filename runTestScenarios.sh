#/bin/sh
set -e

signalfile=$1

function orchestratorLog() {
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo -e "[$now | Orchestrator | INFO] $1"
}

function waitForSeconds() {
        wait=$1
        orchestratorLog "Waiting ${wait} seconds"
        sleep $wait
}

orchestratorLog "Orchestrator Started"

waitForSeconds 60

orchestratorLog "Commencing tests"

export ROOT_DIR=$(pwd)

pushd scenarios

./generatedArtifacts/createOneArtifact.sh
waitForSeconds 60

pushd industrial/gpsExample
./gpsExample.sh
popd
waitForSeconds 60

pushd industrial/salesSystem
./salesSystem.sh
popd
waitForSeconds 60

./generatedArtifacts/createTenRandomlyRelatedArtifacts.sh
waitForSeconds 60

./generatedArtifacts/createTwentyRandomlyRelatedArtifacts.sh
waitForSeconds 60

./generatedArtifacts/createOneHundredRandomlyRelatedArtifacts.sh
waitForSeconds 60

./generatedArtifacts/createTwoHundredRandomlyRelatedArtifactsOfVaryingSizes.sh
waitForSeconds 60

./generatedArtifacts/createOneThousandUnrelatedArtifactsOfFixedSize.sh
waitForSeconds 60

./generatedArtifacts/createFiveHundredRandomlyRelatedArtifactsOfVaryingSizes.sh
waitForSeconds 60

#./testCleanup.sh

popd

orchestratorLog "Scenario execution complete."

#orchestratorLog "Retrieving all blocks from the blockchain."
#./getAllBlocks.sh

if [ -z "${signalfile}" ]; then
        orchestratorLog "No signal file defined."
else
        orchestratorLog "Touching signal file ${signalfile}"
        touch ${signalfile}
fi

orchestratorLog "Done."
