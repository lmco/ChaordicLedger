#!/bin/sh

tempdir=tmpdir
mkdir -p $tempdir

for file in $(find . -type f -name \*.jar)
do
  echo $file
  unzip -o $file -d $tempdir
done

unzip -o fabric-chaincode-example-gradle-1.0-SNAPSHOT.jar -d $tempdir
