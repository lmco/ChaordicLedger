#/bin/sh

# Poll the metrics on an interval specified in seconds

while :
do
    # Use ISO-8601 formatting for UTC timestamp
    date -u '+%Y-%m-%dT%H:%M:%SZ'
    kubectl top pods -n chaordicledger --containers
    echo "---"
    sleep 5
done
