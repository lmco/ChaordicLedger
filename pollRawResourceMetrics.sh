#/bin/sh

# Poll the metrics on an interval specified in seconds

export outdir=$1
export wait=$2

mkdir -p $outdir

while :
do
    # Use ISO-8601 formatting for UTC timestamp
    timestamp=$(date -u '+%Y%m%dT%H%M%SZ')

    # A timestamp is included in each sample, which likely won't directly align with the timestamp capture above.
    # The timestamp is used to keep the sample's filenames unique.
    kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods -n chaordicledger | jq '. | del ( ."items"[] | select(.metadata.namespace != "chaordicledger"))' > ${outdir}/${timestamp}_sample.json
      
    echo "[${timestamp}] Waiting ${wait} to gather next sample"
    sleep ${wait}
done
