#!/bin/sh

function check_return_code() {
  app=$1
  params=$2

  $app $params > /dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    echo "Application '${app}' is not available."
    return 1
  fi
}

check_return_code "docker" "version"
check_return_code "kind" "version"
check_return_code "kubectl" "version"
check_return_code "jq" "--version"
