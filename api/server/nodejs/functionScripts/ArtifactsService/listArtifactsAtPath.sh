#!/bin/sh
set -x
start=$(date +%s%N)

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

end=$(date +%s%N)
duration=$(( end - start ))

echo "{ \"file\" : \"$friendlyName\", \"durationInNanoseconds\": \"$duration\", \"result\": $result }"
