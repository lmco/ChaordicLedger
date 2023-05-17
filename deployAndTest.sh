#/bin/bash

set -e

function syslog() {
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$now] $1"
}

pushd infrastructure

if [ "${CL_RELOAD_ENV}" == "false" ]; then
  syslog "Not establishing resources via Terraform"
else
  syslog "Establishing resources via Terraform"
  ./runTerraform.sh
fi

syslog "Establishing platform via Ansible"
./runAnsible.sh

popd

echo "[$now] Done."
