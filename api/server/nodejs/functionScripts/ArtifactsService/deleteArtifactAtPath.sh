#!/bin/sh
set -x
start=$SECONDS

result=$(ipfs files rm {{artifactPath}})

duration=$(( SECONDS - start ))
echo $result
