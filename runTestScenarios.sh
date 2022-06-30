#/bin/sh
set -e

export ROOT_DIR=$(pwd)

pushd scenarios

#./generatedArtifacts/createOneArtifact.sh
#./testCleanup.sh
#./generatedArtifacts/createTenRandomlyRelatedArtifacts.sh
#./testCleanup.sh
./generatedArtifacts/createTwentyRelatedArtifacts.sh
#./testCleanup.sh
#pushd industrial/gpsExample
#./gpsExample.sh
#popd
#./testCleanup.sh

popd
