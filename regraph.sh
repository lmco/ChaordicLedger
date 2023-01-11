#!/bin/sh
timestamp=20221212T213421Z
sampledir=/tmp/cleval_regraph/samples_reduced_for_regraphing

datadir=/tmp/cleval_regraph/samples_formatted_for_regraphing
plotDir=/tmp/cleval_regraph/samples_regraphed
mkdir -p ${datadir}
mkdir -p ${plotDir}
datafile=${datadir}/${timestamp}_samples_formatted.csv

./convertRawMetricsToCSV.sh ${sampledir} ${datafile}

now=$(date -u '+%Y%m%dT%H%M%SZ')
echo "[$now] Visualizing the formatted samples."

python3 metricsVisualizer.py -i ${datafile} -c CPU_in_nanocores -p ${timestamp} -o ${plotDir}
python3 metricsVisualizer.py -i ${datafile} -c Memory_in_Kibibytes -p ${timestamp} -o ${plotDir}