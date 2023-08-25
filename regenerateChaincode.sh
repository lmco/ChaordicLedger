#!/bin/sh

set -e

rm -rf ../Obsidian/target/*
pushd ../Obsidian
mv src/test src/test_save  
mkdir src/test
sbt assembly
popd
rm -rf out/*
../Obsidian/bin/obsidianc obsidian/contracts/simple/lightswitch.obs --output-path out/
DIR=$(pwd)
pushd out/LightSwitch
cp $DIR/build.gradle .
pwd
#gradle --no-daemon -Dhttp.proxyHost=proxy-zsgov.external.lmco.com -Dhttp.proxyPort=80 -Dhttps.proxyHost=proxy-zsgov.external.lmco.com -Dhttps.proxyPort=80 clean getDeps build
gradle --no-daemon -Dhttp.proxyHost=proxy-zsgov.external.lmco.com -Dhttp.proxyPort=80 -Dhttps.proxyHost=proxy-zsgov.external.lmco.com -Dhttps.proxyPort=80 clean build shadowJar #-x checkstyleMain -x checkstyleTest 
pushd build/libs

java -classpath ./*.jar -jar fabric-chaincode-example-gradle-1.0-SNAPSHOT.jar
