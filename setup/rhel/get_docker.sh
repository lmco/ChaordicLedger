#!/bin/sh

echo "proxy=${http_proxy}" | sudo tee -a /etc/yum.conf
sudo dnf -y install yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf -y install \
                docker-ce \
                docker-ce-cli \
                containerd.io
