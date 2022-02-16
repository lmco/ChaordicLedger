#!/bin/sh

./cleanup_hyperledger.sh

docker image ls
docker image prune -af
docker image ls
