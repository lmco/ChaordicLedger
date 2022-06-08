#/bin/sh

set -e

rm -rf ../Obsidian/target/*
pushd ../Obsidian
sbt assembly
popd
rm -rf out/*
../Obsidian/bin/obsidianc obsidian/contracts/simple/lightswitch.obs --output-path out/
DIR=$(pwd)
pushd out/LightSwitch
cp $DIR/build.gradle .
cp /home/cloud-user/git/ChaordicLedger/chaincode/lightswitch/docker/Dockerfile .
pwd
#gradle -Dhttp.proxyHost=proxy-zsgov.external.lmco.com -Dhttp.proxyPort=80 -Dhttps.proxyHost=proxy-zsgov.external.lmco.com -Dhttps.proxyPort=80 clean getDeps build
docker build .
