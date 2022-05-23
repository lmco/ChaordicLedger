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
  provision_persistent_volumes
  claim_persistant_volumes
  create_service
}

function create_service() {
  ipfs_config=../config/ipfs_service.yaml
  kubectl -n $NS apply -f ${ipfs_config} || true
}

function create_ipfs() {
  init_storage_volumes
}

function purge_storage_volumes() {
  kubectl delete pv --all
}

function purge_storage_volume_claims() {
  kubectl delete pvc --all
}
