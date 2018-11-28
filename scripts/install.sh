#!/usr/bin/env bash

set -o errexit

cd "$HELM_PLUGIN_DIR"

# Find correct archive name
unameOut="$(uname -s)"

case "${unameOut}" in
    Linux*)     OS=Linux;;
    Darwin*)    OS=Darwin;;
    *)          OS="UNKNOWN:${unameOut}"
esac

VERSION="${1//v/}"

echo "Installing Tiller v${VERSION} ..."

ARCH=$(uname -m)
# shellcheck disable=SC2086
COMPARE_VERSION=$(./scripts/semver compare $VERSION 2.11.0)

os="$(echo "${OS}" | tr '[A-Z]' '[a-z]')"

if [[ ${COMPARE_VERSION} -ge 0 ]]; then
  # Helm v2.11 and versions above
  URL=https://storage.googleapis.com/kubernetes-helm/helm-v"${VERSION}"-"${os}"-amd64.tar.gz
else
  # Helm v2.10 and versions below
  URL=https://storage.googleapis.com/helm-tiller/tiller-v"${VERSION}"_"${OS}"_x86_64.tgz
fi

if [ "$URL" = "" ]
then
    echo "Unsupported OS / architecture: ${OS}_${ARCH}"
    exit 1
fi
# shellcheck disable=SC1117
FILENAME=$(echo "${URL}" | sed -e "s/^.*\///g")

# Download archive
if [[ -n $(command -v curl) ]]
then
    curl -sSL -O "$URL"
elif [[ -n $(command -v wget) ]]
then
    wget -q "$URL"
else
    echo "Need curl or wget"
    exit -1
fi

# Install to bin
if [[ ${COMPARE_VERSION} -ge 0 ]]; then
  # Helm v2.11 and versions above
  rm -rf bin && mkdir bin && tar xvf "$FILENAME" -C bin --strip=1 "${os}"-amd64/tiller > /dev/null && rm -f "$FILENAME"
else
  # Helm v2.10 and versions below
  rm -rf bin && mkdir bin && tar xzvf "$FILENAME" -C bin > /dev/null && rm -f "$FILENAME"
fi
