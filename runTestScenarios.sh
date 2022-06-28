#/bin/sh
set -e

export ROOT_DIR=$(pwd)

pushd scenarios/randomArtifacts

#./createOneArtifact.sh
#./testCleanup.sh
#./createTenRandomlyRelatedArtifacts.sh
#./testCleanup.sh
./createTwentyRelatedArtifacts.sh
#./testCleanup.sh

popd
