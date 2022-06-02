#!/bin/sh
set -x
now=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
echo "$now The quick brown fox jumps over the lazy dog." | ipfs files write --create --parents {{artifactPath}}
