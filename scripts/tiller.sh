#!/bin/bash -e

cd $HELM_PLUGIN_DIR

function usage() {
  if [[ ! -z "$1" ]]; then
    printf "$1\n\n"
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

    $ helm tiller start my_tiller_namespace

  Example use of `run`, that starts/stops tiller before/after the specified command:

    $ helm tiller run helm list
    $ helm tiller run mytiller-system -- helm list
    $ helm tiller run mytiller-system -- bash -c 'echo running helm; helm list'

  EOF
}

helm_env() {
  if [[ -n "$1" ]]
  then
    # Set namespace
    echo export TILLER_NAMESPACE=${1}
  fi
  echo export HELM_HOST=localhost:44134
}

start_tiller() {
  ./bin/tiller --storage=secret & helm version
  echo "Tiller namespace: $TILLER_NAMESPACE "
}

stop_tiller() {
  pwd
  echo "Stopping Tiller..."
  pkill -f ./bin/tiller
}

COMMAND=$1

shift

case $COMMAND in
start)
  eval $(helm_env "$@")
  start_tiller
  bash
  ;;
run)
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
  eval $(helm_env "${start_args[@]}")
  start_tiller "${start_args[@]}"
  "${args[@]}"
  ;;
stop)
  stop_tiller
  ;;
*)
  usage
  ;;
esac
