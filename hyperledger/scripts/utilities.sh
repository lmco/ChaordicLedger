#!/bin/sh

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing hyperledger utilities."
fi

# Performs substitutions in a template based on known global variables.
function populateTemplate() {
  local templateFile=$1
  local outputPath=$2

  if [ -z "${templateFile}" ]; then
    syslog "ERROR: Failed to populate template. Template File is empty."
    return 1
  elif [ -z "${outputPath}" ]; then
    syslog "ERROR: Failed to populate template. Output Path is empty."
    return 1
  fi

  syslog "Processing template \"${templateFile}\" to create \"${outputPath}\""

  # Note: envsubst only works with exported variables or variables set and then chained into an invocation.
  envsubst < ${templateFile} > ${outputPath}

  # Setting a variable as a 'return' value, for convenience.
  populatedTemplate=${outputPath}
}

function applyPopulatedTemplate() {
  local templateFile=$1
  local outputPath=$2
  local ns=$3

  populateTemplate $templateFile $outputPath

  if [ "${ns}" == "" ]; then
    kubectl apply -f ${populatedTemplate}
  else
    kubectl -n ${ns} apply -f ${populatedTemplate}
  fi

  unset populatedTemplate
}
