#!/bin/bash

set -e

pushd ~/git/ChaordicLedger/infrastructure

if [ -z "$OS_PASSWORD_INPUT" ]
then
  echo "\$OS_PASSWORD_INPUT is empty; enter password:"
  read -s OS_PASSWORD_INPUT

  if [ -z "$OS_PASSWORD_INPUT" ]
  then
    echo "\$OS_PASSWORD_INPUT is empty; cannot proceed."
    exit 1
  fi
else
  echo "\$OS_PASSWORD_INPUT is set!"
fi

. .lmcoenv
. .envfile

./runTerraform.sh
./runAnsible.sh

popd
