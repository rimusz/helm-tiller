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

  Available Commands:
    start   Start Tiller
    stop    Stop Tiller

  Example use with the set namespace:

    $ helm tiller start my_tiller_namespace

  EOF
}

COMMAND=$1

case $COMMAND in
start)
  if [[ -n "$2" ]]
  then
    # Set namespace
    export TILLER_NAMESPACE=${2}
    export HELM_HOST=localhost:44134
    ./bin/tiller --storage=secret & helm version
    /bin/bash
  else
    export HELM_HOST=localhost:44134
    ./bin/tiller --storage=secret & helm version
    /bin/bash
  fi
  ;;
stop)
  pwd
  echo "Stopping Tiller..."
  pkill -f tiller
  ;;
*)
  usage
  ;;
esac
