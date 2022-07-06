#/bin/sh
set -e

export ROOT_DIR=$(pwd)

pushd scenarios

./generatedArtifacts/createOneArtifact.sh
./generatedArtifacts/createTenRandomlyRelatedArtifacts.sh
./generatedArtifacts/createTwentyRandomlyRelatedArtifacts.sh
./generatedArtifacts/createOneHundredRandomlyRelatedArtifacts.sh
./generatedArtifacts/createTwoHundredRandomlyRelatedArtifactsOfVaryingSizes.sh

pushd industrial/gpsExample
 ./gpsExample.sh
popd

./getAllBlocks.sh

#./testCleanup.sh

popd
