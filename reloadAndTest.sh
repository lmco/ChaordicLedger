#/bin/sh

timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
logdir=/tmp/cleval_${timestamp}/logs
mkdir -p ${logdir}
outdir=/tmp/cleval_${timestamp}/samples
mkdir -p ${outdir}

# Reload the cluster
./reload.sh > ${logdir}/${timestamp}_reload_log.txt 2>&1

# Initiate the scenarios as a background process.
./runTestScenarios.sh > ${logdir}/${timestamp}_testsuite_log.txt 2>&1 &

# Start sampling the metrics
./pollRawResourceMetrics.sh > ${logdir}/${timestamp}_testsuite_raw metrics_capture.txt 2>&1

# Note: polling needs manual termination once the scenarios are complete.
