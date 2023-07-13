#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

CORE_PEER_TLS_ENABLED="${CORE_PEER_TLS_ENABLED:-false}"
DEBUG="${DEBUG:-false}"

env | sort

if [[ "${DEBUG,,}" = "true" ]]; then
    echo "DEBUG"
    exec java -Djava.util.logging.config.file=logging.properties -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=localhost:8000 -jar /chaincode.jar
elif [[ "${CORE_PEER_TLS_ENABLED,,}" = "true" ]]; then
    echo "CORE_PEER_TLS_ENABLED=true"
    exec java -Djava.util.logging.config.file=logging.properties -jar /chaincode.jar # todo
else
    echo "Nominal execution"
    exec java -Djava.util.logging.config.file=logging.properties -jar /chaincode.jar
fi
