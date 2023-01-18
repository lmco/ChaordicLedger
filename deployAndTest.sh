#/bin/bash

function syslog() {
  now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
  echo "[$now] $1"
}

pushd infrastructure

syslog "Establishing resources via Terraform"
./runTerraform.sh

syslog "Establishing platform via Ansible"
./runAnsible.sh

popd

echo "[$now] Done."
