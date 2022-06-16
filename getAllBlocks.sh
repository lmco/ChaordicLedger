#!/bin/sh

blocknumber=3
outdir="outputs"
mkdir -p $outdir

prevFile=""
while true
do
  echo "Prev file: ${prevFile}"
  echo "Next block number: ${blocknumber}"
  currentResult=$(curl -X GET "http://localhost:8080/v1/numberedblock/${blocknumber}" -H "accept: application/json")
  currentFile=$outdir/block${blocknumber}.json

  validation=$(cat $currentFile | jq)

  if [ $? -ne 0 ]
  then
    break
  done

  echo $currentResult > $currentFile

  # if [ -f "$prevFile" ]
  # then
  #   result=$(diff $prevFile $currentFile)
  #   if [ $? -eq 0 ]
  #   then
  #     break
  #   fi
  # fi

  prevFile=$currentFile
  blocknumber=$((blocknumber+1))
done
