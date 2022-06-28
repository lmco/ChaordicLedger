#!/bin/sh
set -x
start=$SECONDS

result=$(ipfs files read "/graph.json")

duration=$(( SECONDS - start ))
echo "{ \"durationInSeconds\": \"$duration\", \"result\": \"$result\" }"
