#/bin/sh
set -e

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
./generatedArtifacts/createFiveHundredRandomlyRelatedArtifactsOfVaryingSizes.sh

#./testCleanup.sh

popd

./getAllBlocks.sh
