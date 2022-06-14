#!/bin/sh
set -x
now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

data="{{body}}"

echo "$data" > /tmp/data.json

ipfs object put /tmp/data.json
#echo "$now The quick brown fox jumps over the lazy dog." | ipfs files write --create --parents {{artifactPath}}
