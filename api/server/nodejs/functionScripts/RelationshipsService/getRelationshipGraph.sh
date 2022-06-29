#!/bin/sh
set -x
start=$SECONDS

result=$(ipfs files read "/graph.json")

if [ "$result" == "" ]
then
      result="\"\""
fi

duration=$(( SECONDS - start ))
echo "{ \"durationInSeconds\": \"$duration\", \"result\": $result }"
