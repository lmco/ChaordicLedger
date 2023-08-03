#!/bin/sh

sudo apt-get -y update

# Note: libdigest-sha-perl contains the 'shasum' tool.
sudo apt-get -y install \
                git \
                build-essential \
                ca-certificates \
                curl \
                gnupg \
                libdigest-sha-perl \
                lsb-release \
