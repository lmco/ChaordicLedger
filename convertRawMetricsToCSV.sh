#!/bin/sh

# Poll the metrics on an interval specified in seconds

export sampleDir=$1
export datafile=$2

echo "Timestamp,Pod_Name,CPU_in_nanocores,Memory_in_Kibibytes" >$datafile

for filename in $(ls ${sampleDir}); do
        absolutePath=${sampleDir}/$filename
        #baseFileName="$(basename "$filename" | sed 's/\(.*\)\..*/\1/')"
        #jq -r '.items[] | (.metadata.creationTimestamp + "," + (.metadata.labels.app + "," + .containers[].usage.cpu + "," + .containers[].usage.memory)' ${filename} | sed "s|n,|,|g" | sed "s|Ki||g" > ${formattedoutdir}/${baseFileName}.txt

        # Scale of units isn't guaranteed to always be nanocores and kibibytes
        # Need to normalize the file.
        # Scale micro to nano by "multiplying" by 1000. Note: the \1 is a backreference to the parenthetical capture.
        # Scale MiB to KiB by "multiplying" by 1024; this isn't precise, but should be representative for our purposes.
        # As far as I can tell, sed doesn't support in-lined arithmetic expressions, though something like awk could.
        jq -r '.items[] | (.metadata.creationTimestamp + "," + .metadata.labels.app + "," + .containers[].usage.cpu + "," + .containers[].usage.memory)' ${absolutePath} |
                sed "s|n,|,|g" |
                sed "s|Ki||g" |
                sed 's|\(,[0-9]*\)u,|\1000,|g' |
                sed 's|\(,[0-9]*\)Mi$|\1024|g' >>${datafile}
done
