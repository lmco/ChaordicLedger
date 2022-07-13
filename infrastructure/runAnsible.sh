#!/bin/bash

set -e

export ANSIBLE_HOST_KEY_CHECKING=false

playbooks=("prerequisites" "tools" "chaordicledger")

for playbook in ${playbooks[@]}; do
  ansible-playbook ansible/roles/${playbook}.yml \
    -i $TF_VAR_inventoryFile \
    --key-file $CHAORDICLEDGER_TERRAFORM_KEYFILE
done
