#!/bin/sh

set -x
defaultFile=/tmp/default.txt
echo "The quick brown fox jumps over the lazy dog." > $defaultFile
ipfs add $defaultFile
