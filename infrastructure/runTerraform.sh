#!/bin/bash

set -e

. .lmcoenv
. .envfile

pushd terraform

if [[ -d $TERRAFORM_TMP_PATH ]]
then
  echo "Tearing-down existing environment."
  terraform plan -destroy -out $TERRAFORM_PLAN_FILE -var="inventoryFile=$TF_VAR_inventoryFile" -input=false
  terraform apply $TERRAFORM_PLAN_FILE
  rm -rf $TERRAFORM_TMP_PATH
fi

mkdir -p $TERRAFORM_TMP_PATH
terraform init -input=false
terraform plan -out $TERRAFORM_PLAN_FILE -var="inventoryFile=$TF_VAR_inventoryFile" -input=false
terraform apply -input=false $TERRAFORM_PLAN_FILE

date
waitTime=1800
echo "Waiting $waitTime seconds for the first-boot autoconfig to finish."
sleep $waitTime
date

echo "Done waiting. Check each host with 'ssh -i $CHAORDICLEDGER_TERRAFORM_KEYFILE <USER>@<IPAddress>' to ensure the first-boot behavior is complete."
echo "(e.g.: check the ~/initial-maintenance.log* file to see if the play recap indicates 0 failed items.)"

popd
