#!/bin/sh
set -x

path="{{path}}"
files=$(ipfs files ls $path)

retval="{ \"path\": \"$path\",\"files\":["
for file in $files
do
  retval="${retval}\"$file\","
done

# Remove last comma from variable
retval="${retval%?}]}"
echo $retval | tr -d "\n"
