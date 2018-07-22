#!/bin/bash -e

COMMAND=$1

case $COMMAND in
start)
  NAMESPACE=$1
  STORAGE=$2
  if [[ -n "$1" && -n "$2" ]]
  then
    # Set namespace and storage driver
    export TILLER_NAMESPACE=${NAMESPACE}
    ../bin/tiller --storage=${STORAGE} & helm version
  elif [[ -n "$1" && -z "$2" ]]
  then
    # Set namespace
    export TILLER_NAMESPACE=${NAMESPACE}
    ../bin/tiller & helm version
  elif [[ -n "$2" && -z "$1" ]]
  then
    # Set storage driver
    ../bin/tiller --storage=${STORAGE} & helm version
  else
      ../bin/tiller & helm version
  fi

  ;;
stop)
  echo "Stopping Tiller..."
  pkill -f tiller
  ;;
*)
  usage
  ;;
esac

function usage() {
  if [[ ! -z "$1" ]]; then
    printf "$1\n\n"
  fi
  cat <<'  EOF'
  Helm plugin for using Tiller locally

  Usage:
    helm tiller start [tiller_namespace] [tiller_storage]
    helm tiller stop

  Available Commands:
    start   Start Tiller
    stop    Stop Tiller

  Example to use with the set namespace and storage Secret:

    $ helm tiller start my_tiller_namespace secret

  EOF
}
