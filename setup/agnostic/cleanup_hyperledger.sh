#!/bin/sh

docker container ls -a
docker ps --format "{{.ID}}" | xargs docker container stop
docker container prune -f
docker container ls -a
docker image ls
docker image prune -af
docker image ls
