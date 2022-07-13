#!/bin/bash

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

mkdir -p $TERRAFORM_TMP_PATH
pushd terraform

terraform init -input=false
terraform plan -out $TERRAFORM_PLAN_FILE -var="inventoryFile=$TF_VAR_inventoryFile" -input=false
terraform apply -input=false $TERRAFORM_PLAN_FILE
popd

# waitTime=900
# echo "Waiting $waitTime seconds for the first-boot autoconfig to finish."
# sleep $waitTime

export ANSIBLE_HOST_KEY_CHECKING=false

playbooks=("prerequisites" "tools" "chaordicledger")

for playbook in ${playbooks[@]}; do
  ansible-playbook ansible/roles/${playbook}.yml -i $TF_VAR_inventoryFile --key-file $CHAORDICLEDGER_TERRAFORM_KEYFILE
done

popd
