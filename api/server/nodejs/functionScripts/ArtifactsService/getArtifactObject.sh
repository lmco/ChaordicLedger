#!/bin/sh
set -x
start=$SECONDS

result=$(ipfs object get {{artifactID}})

duration=$(( SECONDS - start ))

if [ "$result" == "\n" ]
then
  result="{}"
fi

echo "{ \"durationInSeconds\": \"$duration\", \"result\": $result }"
