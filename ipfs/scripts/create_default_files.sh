#!/bin/sh

set -x
now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
#defaultFileName=$(echo $now | sed "s|[:-]||g")
defaultFileName="TheDefaultFile"
defaultFilePath=/tmp/$defaultFileName.txt
# defaultFile=/tmp/default.txt
# echo "The quick brown fox jumps over the lazy dog." > $defaultFile
#ipfs add $defaultFile -Q
echo "$now The quick brown fox jumps over the lazy dog." | ipfs files write --create --parents $defaultFilePath
echo $defaultFilePath
