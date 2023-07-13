#!/bin/sh

blocknumber=0
outdir="/tmp/chaordicledger"
blockdir=$outdir/blocks
blockinfo=$outdir/blockinfo
mkdir -p $blockdir
mkdir -p $blockinfo

rm $blockdir/*
rm $blockinfo/*

latestBlock=$(curl -s -X GET "http://localhost:8080/v1/blockchain/getLatestBlock" -H "accept: application/json" | jq .header.number | tr -d '\"')
prevFile=""

while [ $blocknumber -le $latestBlock ]; do
        echo "Retrieving block number: ${blocknumber}"
        blockname=block$(printf %03d ${blocknumber})
        currentFile=$blockdir/${blockname}.json
        currentResult=$(curl -s -X GET "http://localhost:8080/v1/blockchain/getNumberedBlock/${blocknumber}" -H "accept: application/json")

        if [ $? -ne 0 ]; then
                echo "Error retrieving block ${blocknumber}: $currentResult"
                break
        fi

        # Validate
        if [ "$(echo $currentResult | jq .unknown)" == "null" ] && [ "$(echo $currentResult | jq .error)" == "null" ]; then
                echo "Writing block file $currentFile"
                echo $currentResult | jq >$currentFile
                cat $currentFile | jq .data.data[0].payload.header.channel_header >$blockinfo/${blockname}_info.json
        else
                echo "Block $blocknumber does not exist."
                break
        fi

        prevFile=$currentFile
        blocknumber=$((blocknumber + 1))
done

totalblocks=$(($latestBlock + 1)) # Adjust for zero-based indexing.

echo "Retrieved $blocknumber of $totalblocks blocks."
