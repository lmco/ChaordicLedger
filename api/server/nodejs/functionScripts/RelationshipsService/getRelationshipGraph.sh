#!/bin/sh
set -x
start=$(date +%s%N)

result=$(ipfs files read "/graph.json")

if [ "$result" == "" ]
then
      result="\"\""
fi

end=$(date +%s%N)
duration=$(( end - start ))

echo "{ \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
