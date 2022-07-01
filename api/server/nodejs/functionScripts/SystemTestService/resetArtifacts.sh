#!/bin/sh
set -x

pushd ..
./network ipfsReset
./network graphinit
popd
