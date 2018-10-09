#!/usr/bin/env bash

set -o errexit

CURRENT_FOLDER=$(pwd)

cd "$HELM_PLUGIN_DIR"

function usage() {
  if [[ -n "$1" ]]; then
    printf "%s\\n\\n" "$1"
  fi
  cat <<'  EOF'
  Helm plugin for using Tiller locally

  Usage:
    helm tiller install
    helm tiller start [tiller_namespace]
    helm tiller start-ci [tiller_namespace]
    helm tiller stop
    helm tiller run [tiller_namespace] -- [command] [args]

  Available Commands:
    install   Manually install/upgrade Tiller binary
    start     Start Tiller and open new pre-set shell
    start-ci  Start Tiller without opening new shell
    run       Start Tiller and run arbitrary command within the environment
    stop      Stop Tiller

  Example use with the set namespace:

    $ helm tiller start my-tiller-namespace

  Example use of `run`, that starts/stops tiller before/after the specified command:

    $ helm tiller run helm list
    $ helm tiller run my-tiller-namespace -- helm list
    $ helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'

  EOF
}

check_helm() {
  # Check if helm is installed
  if ! command -v helm >/dev/null 2>&1; then
    echo "Helm client is not installed!"
    exit 0
  fi
}

check_install_tiller() {
  INSTALLED_HELM=$(helm version -c --short | awk -F[:+] '{print $2}' | cut -d ' ' -f 2)
  echo "Installed Helm version $INSTALLED_HELM"
  # check if the tiller binary exists
  if [ ! -f ./bin/tiller ]; then
    # check if tiller binary is already installed in the path
    if  command -v tiller >/dev/null 2>&1; then
      EXISTING_TILLER=$(command -v tiller)
      mkdir -p ./bin
      cp "${EXISTING_TILLER}" ./bin/
      INSTALLED_TILLER=$(./bin/tiller --version)
      echo "Copied found $EXISTING_TILLER to helm-tiller/bin"
    else
      INSTALLED_TILLER=v0.0.0
    fi
  else
    INSTALLED_TILLER=$(./bin/tiller --version)
    echo "Installed Tiller version $INSTALLED_TILLER"
  fi
  # check if tiller and helm versions match
  if [[ "${INSTALLED_HELM}" == "${INSTALLED_TILLER}" ]]; then
    echo "Helm and Tiller are the same version!"
  else
    ./scripts/install.sh "$INSTALLED_HELM"
  fi
}

helm_env() {
  if [[ -n "$1" ]]
  then
    # Set namespace
    echo export TILLER_NAMESPACE="${1}"
  fi
  echo export HELM_HOST=localhost:44134
}

start_tiller() {
  echo "Starting Tiller..."
  { ./bin/tiller --storage=secret --listen=localhost:44134 & } 2>/dev/null
  echo "Tiller namespace: $TILLER_NAMESPACE"
}

run_tiller() {
  echo "Starting Tiller..."
  { ./bin/tiller --storage=secret --listen=localhost:44134 & } 2>/dev/null
  cd "${CURRENT_FOLDER}"
}

stop_tiller() {
  echo "Stopping Tiller..."
  pkill -f ./bin/tiller
}

COMMAND=$1

# do shift only if some argument is provided
if [[ -n "$1" ]]; then
  shift
fi

case $COMMAND in
install)
  check_helm
  check_install_tiller
    ;;
start)
  check_helm
  check_install_tiller
  eval '$(helm_env "$@")'
  start_tiller
  cd "${CURRENT_FOLDER}"
  # open user's preferred shell
  if [[ ! -z "$SHELL" ]]; then
      $SHELL
  else
      bash
  fi
  ;;
start-ci)
  check_helm
  check_install_tiller
  eval '$(helm_env "$@")'
  start_tiller
  ;;
run)
  check_helm
  check_install_tiller
  start_args=()
  args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -- ) start_args=( "${args[@]}" ); args=(); shift ;;
      * ) args+=("${1}"); shift ;;
    esac
  done
  trap stop_tiller EXIT
  eval '$(helm_env "${start_args[@]}")'
  run_tiller "${start_args[@]}"
  # shellcheck disable=SC2145
  echo Running: "${args[@]}"
  echo
  "${args[@]}"
  ;;
stop)
  stop_tiller
  ;;
*)
  usage "$@"
  ;;
esac
