#!/bin/sh
set -x
start=$SECONDS

ipfs object get {{artifactID}}
#ipfs files read {{artifactID}}

duration=$(( SECONDS - start ))
echo $result
