#!/bin/sh

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing hyperledger prerequisite checks."
fi

function check_return_code() {
  app=$1
  params=$2

  $app $params > /dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    syserr "Application '${app}' is not available."
    return 1
  fi
}

check_return_code "curl" "--version"
check_return_code "docker" "version"
check_return_code "kind" "version"
check_return_code "jq" "--version"
check_return_code "shasum" "-v"
check_return_code "npm" "-v"
check_return_code "helm" "version"

# Note: Using the version option with kubectl will cause a non-zero return code 
# if the client and the server have drifted too far in version.
check_return_code "kubectl" "" 
