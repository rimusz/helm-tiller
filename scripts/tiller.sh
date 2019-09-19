#!/usr/bin/env bash

set -o errexit

: "${HELM_TILLER_SILENT:=false}"
: "${HELM_TILLER_PORT:=44134}"
: "${HELM_TILLER_PROBE_PORT:=44135}"
: "${HELM_TILLER_STORAGE:=secret}"
: "${HELM_TILLER_LOGS:=false}"
: "${HELM_TILLER_LOGS_DIR:=/dev/null}"
: "${HELM_TILLER_HISTORY_MAX:=20}"
: "${CREATE_NAMESPACE_IF_MISSING:=true}"

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
    env       Setup environment variables
    run       Start Tiller and run arbitrary command within the environment
    stop      Stop Tiller

  Available environment variables:
    'HELM_TILLER_SILENT=true' - silence plugin specific messages, only `helm` cli output will be printed.
    'HELM_TILLER_PORT=44140' - change Tiller port, default is `44134`.
    'HELM_TILLER_PROBE_PORT=44141' - change Tiller probe port, default is `44135`. Requires Helm >= 2.14.
    'HELM_TILLER_STORAGE=configmap' - change Tiller storage to `configmap`, default is `secret`.
    'HELM_TILLER_LOGS=true' - store Tiller logs in '$HOME/.helm/plugins/helm-tiller/logs'.
    'HELM_TILLER_LOGS_DIR=/some_folder/tiller.logs' - set a specific folder/file for Tiller logs.
    'HELM_TILLER_HISTORY_MAX=20' - change maximum number of releases kept in release history by Tiller.
    'CREATE_NAMESPACE_IF_MISSING=false' - indicate whether the namespace should be created if it does not exist.

  Example use with the set namespace:
    $ helm tiller start my-tiller-namespace

  Example use of `run`, that starts/stops tiller before/after the specified command:
    $ helm tiller run helm list
    $ helm tiller run my-tiller-namespace -- helm list
    $ helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'

  Example use of `env` to set environment variables for start-ci:
    $ source <(helm tiller env my-tiller-namespace)

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
  if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
      echo "Installed Helm version $INSTALLED_HELM"
  fi
  # check if the tiller binary exists
  if [ ! -f ./bin/tiller ]; then
    # check if tiller binary is already installed in the path
    if  command -v tiller >/dev/null 2>&1; then
      EXISTING_TILLER=$(command -v tiller)
      mkdir -p ./bin
      mkdir -p ./logs
      cp "${EXISTING_TILLER}" ./bin/
      INSTALLED_TILLER=$(./bin/tiller --version)
      if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
          echo "Copied found $EXISTING_TILLER to helm-tiller/bin"
      fi
    else
      INSTALLED_TILLER=v0.0.0
    fi
  else
    INSTALLED_TILLER=$(./bin/tiller --version)
    if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
        echo "Installed Tiller version $INSTALLED_TILLER"
    fi
  fi
  # check if tiller and helm versions match
  if [[ "${INSTALLED_HELM}" == "${INSTALLED_TILLER}" ]]; then
    if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
        echo "Helm and Tiller are the same version!"
    fi
  else
    ./scripts/install.sh "$INSTALLED_HELM"
  fi
}

helm_env() {
  if [[ -n "$1" ]]
  then
    # Set namespace
    echo export TILLER_NAMESPACE="${1}"
    export TILLER_NAMESPACE="${1}"
  fi
  echo export HELM_HOST=127.0.0.1:${HELM_TILLER_PORT}
  export HELM_HOST=127.0.0.1:${HELM_TILLER_PORT}
}

create_ns() {
  if [[ "${CREATE_NAMESPACE_IF_MISSING}" == "true" ]]; then
    if [[ "$3" == "upgrade" ]] || [[ "$3" == "install" ]]; then
      echo "Creating tiller namespace (if missing): $1"
      set +e
      kubectl get ns "$1" &> /dev/null

      if [[ $? -eq 1 ]]
      then
        set -e
        kubectl create ns "$1" &> /dev/null
        kubectl patch ns "$1" -p \
          "{\"metadata\": {\"labels\": {\"name\": \"${1}\"}}}" &> /dev/null
      fi
    fi
  fi
}

tiller_ensure_log_dir() {
    LOG_DIR="${HELM_TILLER_LOGS_DIR%/*}"
    if [[ ! -d "${LOG_DIR}" ]]; then
        echo "Creating folder ${LOG_DIR} for saving tiller logs into ${HELM_TILLER_LOGS_DIR}"
        mkdir -p ${LOG_DIR}
    fi
}

tiller_env() {
  if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
    echo "Starting Tiller..."
  fi
  if [[ "${HELM_TILLER_LOGS}" == "true" ]]; then
    if [[ -z "${HELM_TILLER_LOGS_DIR:-}" ]]; then
        HELM_TILLER_LOGS_DIR="$HELM_PLUGIN_DIR/logs/tiller.logs"
    fi
    export HELM_TILLER_LOGS_DIR
    tiller_ensure_log_dir
  fi
}

start_tiller() {
  tiller_env
  PROBE_LISTEN_FLAG="--probe-listen=127.0.0.1:${HELM_TILLER_PROBE_PORT}"
  # check if we have a version that supports the --probe-listen flag
  ./bin/tiller --help 2>&1 | grep probe-listen > /dev/null || PROBE_LISTEN_FLAG=""
  ( ./bin/tiller --storage=${HELM_TILLER_STORAGE} --listen=127.0.0.1:${HELM_TILLER_PORT} ${PROBE_LISTEN_FLAG} --history-max=${HELM_TILLER_HISTORY_MAX} & 2>"${HELM_TILLER_LOGS_DIR}")
  if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
    echo "Tiller namespace: $TILLER_NAMESPACE"
  fi
}

run_tiller() {
  start_tiller
  cd "${CURRENT_FOLDER}"
}

stop_tiller() {
  if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
    echo "Stopping Tiller..."
  fi
  pkill -9 -f ./bin/tiller
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
  # shellcheck disable=SC2236
  if [[ ! -z "$SHELL" ]]; then
      $SHELL
  else
      bash
  fi
  stop_tiller
  ;;
start-ci)
  check_helm
  check_install_tiller
  echo "Set the following vars to use tiller:"
  helm_env "$@"
  start_tiller
  ;;
env)
  helm_env "$@"
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
  create_ns "${start_args[@]}" "${args[@]}"
  run_tiller "${start_args[@]}"
  # shellcheck disable=SC2145
  if [[ "${HELM_TILLER_SILENT}" == "false" ]]; then
    echo Running: "${args[@]}"
    echo
  fi
  "${args[@]}"
  ;;
stop)
  stop_tiller
  ;;
*)
  usage "$@"
  ;;
esac
