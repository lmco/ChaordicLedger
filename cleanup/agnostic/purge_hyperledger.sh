#!/bin/sh

./cleanup_hyperledger.sh

docker image ls
docker image prune -af
docker image ls

docker volume ls
docker volume prune -f
docker volume ls
