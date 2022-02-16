#!/bin/sh

# Note: libdigest-sha-perl contains the 'shasum' tool.
sudo apt-get -y install \
                git
                ca-certificates \
                curl \
                gnupg \
                libdigest-sha-perl \
                lsb-release \
