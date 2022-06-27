#/bin/sh
set -e

export ROOT_DIR=$(pwd)

pushd scenarios

./createTenRandomlyRelatedArtifacts.sh
#./createTwentyRelatedArtifacts.sh

popd
