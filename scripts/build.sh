#!/bin/bash -e

HELM_PLUGIN_DIR=$(pwd)

# Build Darwin binary
cd $GOPATH
rm -fr src/k8s.io/helm
mkdir -p src/k8s.io
cd src/k8s.io
git clone https://github.com/kubernetes/helm.git
cd helm
git checkout v$TILLER_VERSION
make bootstrap build
cd bin
tar czvf tiller-v${TILLER_VERSION}_Darwin_x86_64.tgz tiller
# Upload to GCS bucket
echo "Upload Tiller Darwin tgz to GCS bucket"
gsutil cp tiller-v${TILLER_VERSION}_Darwin_x86_64.tgz gs://${GCS_BUCKET}
rm -f tiller-v${TILLER_VERSION}_Darwin_x86_64.tgz

# Fetch Linux binary
echo "Extracting Tiller Linux binary from the docker image"
id=$(docker create $TILLER_DOCKER_REGISTRY:v$TILLER_VERSION)
mkdir -p ~/tmp/tiller
docker cp $id:tiller - > ~/tmp/tiller/tiller.tar
docker rm -v $id
cd ~/tmp/tiller
tar xvf ~/tmp/tiller/tiller.tar
rm -f tiller.tar
tar czvf tiller-v${TILLER_VERSION}_Linux_x86_64.tgz tiller
# Upload to GCS bucket
echo "Upload Tiller Linux tgz to GCS bucket"
gsutil cp tiller-v${TILLER_VERSION}_Linux_x86_64.tgz gs://${GCS_BUCKET}
rm -rf tiller

# Make tgz files public
gsutil acl ch -u AllUsers:R gs://${GCS_BUCKET}/*

cd $HELM_PLUGIN_DIR

# Update plugin version
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]
then
  sed -i 's/\(version: \)\(.*\)/\1''"'$TILLER_VERSION'"''/' plugin.yaml
else
  sed -i "" 's/\(version: \)\(.*\)/\1''"'$TILLER_VERSION'"''/' plugin.yaml
fi
