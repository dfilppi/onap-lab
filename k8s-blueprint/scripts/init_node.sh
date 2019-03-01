#!/bin/bash


which kubeadm
while [ $? -ne 0 ]; do
  ctx logger info "waiting for kubeadm to exist"
  sleep 5
  which kubeadm
done

ctx logger info "JOIN=$JOIN"
sudo `echo $JOIN`

