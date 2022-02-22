#!/bin/sh

# function init_namespace() {
#   echo "Creating namespace \"$NS\""

#   kubectl create namespace $NS || true
# }

# # Need to init and load for N number of orgs

# function init_storage_volumes() {
#   echo "Provisioning volume storage"
#   kubectl create -f kube/pv-fabric-org0.yaml || true
#   kubectl -n $NS create -f kube/pvc-fabric-org0.yaml || true
# }

# function load_org_config() {
#   echo "Creating fabric config maps"
#   kubectl -n $NS delete configmap org0-config || true
#   kubectl -n $NS create configmap org0-config --from-file=config/org0
# }
