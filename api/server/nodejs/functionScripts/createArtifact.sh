#!/bin/sh
set -x
defaultFileName=$(uuidgen)
defaultFilePath=/tmp/$defaultFileName.txt
now=`date -u +"%Y-%m-%dT%H:%M:%S%:z"`
echo "$now: The quick brown fox jumps over the lazy dog." > $defaultFile
ipfs add $defaultFile -Q
