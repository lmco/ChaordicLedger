#!/bin/sh
set -x
# This runs on the IPFS image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

result=$(ipfs object get {{artifactID}})

duration=$(( SECONDS - start ))

if [ "$result" == "\n" ]
then
  result="{}"
fi

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

#echo "{ \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
#echo "{ \"artifactID\" : \"{{artifactID}}, \"durationInMicroseconds\": \"$duration\", \"result\": $result }"
echo "{ \"operation\" : \"getArtifactObject\", \"artifactID\" : \"{{artifactID}}\", \"ipfsData\": $result }"
