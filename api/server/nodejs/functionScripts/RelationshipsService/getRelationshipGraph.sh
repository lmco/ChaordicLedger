#!/bin/sh
set -x

# This runs on the IPFS image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

result=$(ipfs files read "/graph.json")

if [ "$result" == "" ]
then
  result="\"\""
fi

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

#echo "{ \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
echo "{ \"durationInMicroseconds\": \"$duration\", \"result\": $result }"
