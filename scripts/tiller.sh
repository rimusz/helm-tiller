#!/bin/bash -e

cd "$HELM_PLUGIN_DIR"

function usage() {
  if [[ ! -z "$1" ]]; then
    printf "%s\\n\\n" "$1"
  fi
  cat <<'  EOF'
  Helm plugin for using Tiller locally

  Usage:
    helm tiller start [tiller_namespace]
    helm tiller stop
    helm tiller run [tiller_namespace] -- [command] [args]

  Available Commands:
    start   Start Tiller
    run     Start Tiller and run arbitrary command within the environment
    stop    Stop Tiller

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

check_tiller() {
  INSTALLED_HELM=$(helm version -c --short | awk -F[:+] '{print $2}' | cut -d ' ' -f 2)
  echo "Installed Helm version $INSTALLED_HELM"
  # check if the binary exists
  if [ ! -f ./bin/tiller ]; then
    INSTALLED_TILLER=v0.0.0
  else
    INSTALLED_TILLER=$(./bin/tiller --version)
    echo "Installed Tiller version $INSTALLED_TILLER"
  fi
  # check if tiller and helm versions match
  if [[ "${INSTALLED_HELM}" == "${INSTALLED_TILLER}" ]]; then
    echo "Helm and Tiller are the same version!"
  else
    ./scripts/install.sh $INSTALLED_HELM
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
  ./bin/tiller --storage=secret & helm version
  echo "Tiller namespace: $TILLER_NAMESPACE"
}

stop_tiller() {
  echo "Stopping Tiller..."
  pkill -f ./bin/tiller
}

COMMAND=$1

# do shift only if some argument is provided
if [[ ! -z "$1" ]]; then
  shift
fi

case $COMMAND in
start)
  check_helm
  check_tiller
  eval '$(helm_env "$@")'
  start_tiller
  bash
  ;;
run)
  check_helm
  check_tiller
  start_args=()
  args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -- ) start_args=( "${args[@]}" ); args=(); shift ;;
      * ) args+=("${1}"); shift ;;
    esac
  done
  trap stop_tiller EXIT
  echo args="${args[@]}"
  eval '$(helm_env "${start_args[@]}")'
  start_tiller "${start_args[@]}"
  "${args[@]}"
  ;;
stop)
  stop_tiller
  ;;
*)
  usage "$@"
  ;;
esac
