#!/bin/bash -e

cd $HELM_PLUGIN_DIR

# Find correct archive name
unameOut="$(uname -s)"

case "${unameOut}" in
    Linux*)     OS=Linux;;
    Darwin*)    OS=Darwin;;
    *)          OS="UNKNOWN:${unameOut}"
esac

if [[ "$1" == "update" ]]
then
  # Use the GitHub API to find the latest version for this project.
  latest_url="https://api.github.com/repos/rimusz/helm-tiller/releases/latest"
  VERSION="$(curl -s $latest_url | grep tag_name | awk '{print $2}' | tr -d ',' | tr -d '"' | tr -d 'v')"
else
  VERSION="$(cat plugin.yaml | grep "version" | cut -d '"' -f 2)"
fi
echo "Installing Tiller plugin v${VERSION} ..."

ARCH=`uname -m`
URL=https://storage.googleapis.com/helm-tiller/tiller-v${VERSION}_${OS}_x86_64.tgz

if [ "$URL" = "" ]
then
    echo "Unsupported OS / architecture: ${OS}_${ARCH}"
    exit 1
fi

FILENAME=`echo ${URL} | sed -e "s/^.*\///g"`

# Download archive
if [ -n $(command -v curl) ]
then
    curl -sSL -O $URL
elif [ -n $(command -v wget) ]
then
    wget -q $URL
else
    echo "Need curl or wget"
    exit -1
fi

# Install to bin
rm -rf bin && mkdir bin && tar xzvf $FILENAME -C bin > /dev/null && rm -f $FILENAME
