#!/bin/sh
set -x
# This runs on the IPFS image, which uses BusyBox's date function, which doesn't support nanoseconds.
#start=$(date +%s%N)
start=${EPOCHREALTIME/./}

path="{{path}}"
files=$(ipfs files ls $path)

# Build JSON list of results
retval="{ \"path\": \"$path\",\"files\":["
for file in $files
do
  retval="${retval}\"$file\","
done

# Remove last comma from variable
retval="${retval%?}]}"
result=$(echo $retval | tr -d "\n")

#end=$(date +%s%N)
end=${EPOCHREALTIME/./}
duration=$(( end - start ))

#echo "{ \"file\" : \"$friendlyName\", \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
echo "{ \"file\" : \"$friendlyName\", \"durationInMicroseconds\": \"$duration\", \"result\": $result }"
