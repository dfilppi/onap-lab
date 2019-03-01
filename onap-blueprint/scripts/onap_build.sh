#!/bin/bash

# builds onap charts, run in root login context
set -e

#oom put there by nodeprep
cd /root
if [ ! -d oom ]; then
  mv /tmp/oom.tgz .
  tar xzf oom.tgz
  rm -f oom.tgz
fi

cd oom/kubernetes

# ignore helm serve errs
nohup helm serve > /tmp/helm.out 2>/tmp/helm.err &
sleep 1
set +e
helm repo remove stable

set -e
make all
