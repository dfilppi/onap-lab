#!/bin/bash

set -e

OUTFILE="/tmp/kubeadm.out"

which kubeadm
while [ $? -ne 0 ]; do
  ctx logger info "waiting for kubeadm to exist"
  sleep 5
  which kubeadm
done

sudo kubeadm init > $OUTFILE 2>&1
TOK=`grep 'kubeadm join' $OUTFILE`
ctx instance runtime-properties join_cmd "$TOK"

ASROOT="sudo -i"

# Kubectl config
$ASROOT mkdir -p .kube
$ASROOT cp -i /etc/kubernetes/admin.conf .kube/config

# Weavenet CNI
VER=`$ASROOT kubectl version`
$ASROOT kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(echo $VER | base64 | tr -d '\n')"

# Disable RBAC
$ASROOT kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts

# Helm

HELM_VERSION=helm-v2.9.1-linux-amd64
HELM_ARCHIVE=${HELM_VERSION}.tar.gz
$ASROOT curl -O https://storage.googleapis.com/kubernetes-helm/${HELM_ARCHIVE}
$ASROOT tar xzf ${HELM_ARCHIVE}
$ASROOT mv linux-amd64/helm /usr/bin
ctx download-resource resources/helm-rbac.yaml '@{"target_path": "/tmp/helm-rbac.yaml"}'
$ASROOT kubectl create -f /tmp/helm-rbac.yaml
set +e  # ignore tiller error, will reschedule when nodes join
$ASROOT helm init --service-account tiller
set -e
ctx download-resource resources/helm-plugins.tgz '@{"target_path": "/tmp/helm-plugins.tgz"}'
$ASROOT tar xzf /tmp/helm-plugins.tgz
$ASROOT cp -r plugins .helm
$ASROOT rm -rf plugins
