#!/bin/sh
set -x
start=$SECONDS

path="{{path}}"
files=$(ipfs files ls $path)

retval="{ \"path\": \"$path\",\"files\":["
for file in $files
do
  retval="${retval}\"$file\","
done

# Remove last comma from variable
retval="${retval%?}]}"
result=$(echo $retval | tr -d "\n")

duration=$(( SECONDS - start ))

echo "{ \"file\" : \"$friendlyName\", \"durationInSeconds\": \"$duration\", \"result\": $result }"
