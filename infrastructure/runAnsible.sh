#!/bin/bash

set -e

. .ansibleEnvfile

export repo_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )/.." &> /dev/null && pwd 2> /dev/null; )";
playbooks=("prerequisites" "tools" "chaordicledger")

for playbook in ${playbooks[@]}; do
  ansible-playbook ansible/roles/${playbook}.yml \
    -i $TF_VAR_inventoryFile \
    --key-file $CHAORDICLEDGER_TERRAFORM_KEYFILE
done
