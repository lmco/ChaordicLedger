#!/bin/sh

# Note: perl-Digest-SHA contains the 'shasum' tool.
sudo dnf -y install \
                git \
                ca-certificates \
                curl \
                gnupg \
                perl-Digest-SHA \
                lsb-release \
