#!/usr/bin/env bash

set -o errexit

HELM_PLUGIN_DIR=$(pwd)

#
cd $GOPATH
rm -fr src/k8s.io/helm
mkdir -p src/k8s.io
cd src/k8s.io
git clone https://github.com/kubernetes/helm.git
cd helm
git checkout v$TILLER_VERSION
# Patch tiller.go with client auth plugins
# Get OS type
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]
then
  SED='sed -i'
else
  SED='sed -i ""'
fi
# Patch tiller.go file
${SED} '/\"google.golang.org\/grpc\/keepalive\"/!{p;d;};n;r '${HELM_PLUGIN_DIR}'/scripts/tiller.patch' cmd/tiller/tiller.go
rm -f 'cmd/tiller/tiller.go""'
#
# fetch dependencies
make bootstrap
# Build Darwin binary
make build
# Build Linux amd64 binary
make docker-binary
#
# tar Darwin binary
cd bin/
tar czvf tiller-v${TILLER_VERSION}_Darwin_x86_64.tgz tiller
# Upload to GCS bucket
echo "Upload Tiller Darwin tgz to GCS bucket"
gsutil cp tiller-v${TILLER_VERSION}_Darwin_x86_64.tgz gs://${GCS_BUCKET}
#
# tar linux binary
cd ../rootfs/
tar czvf tiller-v${TILLER_VERSION}_Linux_x86_64.tgz tiller
# Upload to GCS bucket
echo "Upload Tiller Linux tgz to GCS bucket"
gsutil cp tiller-v${TILLER_VERSION}_Linux_x86_64.tgz gs://${GCS_BUCKET}
#
# Make tgz files public
gsutil acl ch -u AllUsers:R gs://${GCS_BUCKET}/*
