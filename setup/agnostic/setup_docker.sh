#!/bin/sh

sudo mkdir -p /etc/systemd/system/docker.service.d/
proxy_config="/etc/systemd/system/docker.service.d/http-proxy.conf"
sudo touch /etc/systemd/system/docker.service.d/http-proxy.conf
echo "[Service]" | sudo tee -a $proxy_config
echo "Environment=\"HTTP_PROXY=${HTTPS_PROXY}\"" | sudo tee -a $proxy_config
echo "Environment=\"http_proxy=${http_proxy}\"" | sudo tee -a $proxy_config
echo "Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\"" | sudo tee -a $proxy_config	
echo "Environment=\"https_proxy=${https_proxy}\"" | sudo tee -a $proxy_config
echo "Environment=\"NO_PROXY=${NO_PROXY}\"" | sudo tee -a $proxy_config
echo "Environment=\"no_proxy=${no_proxy}\"" | sudo tee -a $proxy_config
sudo usermod -aG docker ${USER}
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo su $USER # or log off/on

docker run hello-world
