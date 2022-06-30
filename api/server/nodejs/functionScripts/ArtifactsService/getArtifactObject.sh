#!/bin/sh
set -x
start=$(date +%s%N)

result=$(ipfs object get {{artifactID}})

duration=$(( SECONDS - start ))

if [ "$result" == "\n" ]
then
  result="{}"
fi

end=$(date +%s%N)
duration=$(( end - start ))

echo "{ \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
