#!/bin/sh

function provision_persistent_volumes()
{
  echo $PWD

  pv_config=../config/ipfs_pv.yaml
  kubectl create -f ${pv_config} || true
}

function claim_persistant_volumes()
{
  pvc_config=../config/ipfs_pvc.yaml
  kubectl -n $NS create -f ${pvc_config} || true
}

function init_storage_volumes() {
  create_storage_type
  provision_persistent_volumes
  claim_persistant_volumes
}

function create_service() {
  ipfs_config=../config/ipfs_service.yaml
  kubectl -n $NS apply -f ${ipfs_config} || true
  kubectl -n $NS rollout status deploy/chaordicledger-ipfs
}

function create_storage_type() {
  ipfs_config=../config/ipfs_storage_type.yaml
  kubectl -n $NS apply -f ${ipfs_config} || true
}

function create_sample_file() {
  sleep 10
  echo "Creating sample file"
  result=$(cat create_default_files.sh | exec kubectl -n $NS exec deploy/chaordicledger-ipfs -i -- /bin/sh)
  sleep 10
  echo "Parsing identifier \"$result\""
  identifier=$(echo $result | awk '{print $2;}')
  sleep 10
  echo "Retrieving file $identifier"
  fileContents=$(curl localhost/ipfs/$identifier)
  echo $fileContents
}

function create_ipfs() {
  init_storage_volumes
  create_service
  create_sample_file
}

function delete_ipfs() {
  kubectl delete -f ../config/ipfs_service.yaml
  kubectl delete -f ../config/ipfs_pvc.yaml -n $NS
  kubectl delete -f ../config/ipfs_pv.yaml -n $NS
  kubectl delete -f ../config/ipfs_storage_type.yaml -n $NS
}
