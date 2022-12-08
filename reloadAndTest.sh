#/bin/sh
timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
outdirRoot=/tmp/cleval_${timestamp}

echo "[${timestamp}] Output dir is ${outdirRoot}"

logdir=${outdirRoot}/logs
mkdir -p ${logdir}

sampledir=${outdirRoot}/samples
mkdir -p ${sampledir}

formattedSampleDir=${sampledir}_formatted
mkdir -p ${formattedSampleDir}

plotDir=${sampledir}_plotted
mkdir -p ${plotDir}

# Reload the cluster
./reload.sh > ${logdir}/${timestamp}_reload_log.txt 2>&1

# Initiate the scenarios as a background process.
./runTestScenarios.sh > ${logdir}/${timestamp}_testsuite_log.txt 2>&1 &

# Start sampling the metrics
pollingScript="pollRawResourceMetrics.sh"
path=$(realpath ${pollingScript})
now=$(date -u '+%Y%m%dT%H%M%SZ')
echo "[$now] Run 'sudo fuser ${path} -k' to stop metrics gathering."
./${pollingScript} ${sampledir} 5 > ${logdir}/${timestamp}_testsuite_raw_metrics_capture.txt 2>&1

# Note: polling needs manual termination once the scenarios are complete.
datafile=${formattedSampleDir}/${timestamp}_samples_formatted.csv

now=$(date -u '+%Y%m%dT%H%M%SZ')
echo "[$now] Formatting gathered samples into a single datafile: ${datafile}"
./convertRawMetricsToCSV.sh ${sampledir} ${datafile}

now=$(date -u '+%Y%m%dT%H%M%SZ')
echo "[$now] Visualizing the formatted samples."

python3 metricsVisualizer.py -i ${datafile} -c CPU_in_nanocores -o ${plotDir}
python3 metricsVisualizer.py -i ${datafile} -c Memory_in_Kibibytes -o ${plotDir}

now=$(date -u '+%Y%m%dT%H%M%SZ')
echo "Done"
