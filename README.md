# Run Helm Tiller locally aka Tillerless Helm

[Helm](https://helm.sh) plugin for using [Tiller](https://docs.helm.sh/using_helm/#installing-tiller) locally.

**Note:** For a better security Tiller plugin comes with preset storage as `Secret`.

## Installation

Install the latest version:

```shell
$ helm plugin install https://github.com/rimusz/helm-tiller
```

List available releases:

```shell
$ git tag
v2.8.2
v2.9.1
```

Install a specific Tiller version:

```shell
$ helm plugin install https://github.com/rimusz/helm-tiller --version 2.9.1
```

## Usage

Usage:

```  
$ helm tiller start [tiller_namespace]
$ helm tiller stop
$ helm tiller run [tiller_namespace] -- [command] [args]
```

Available Commands:

```
start   Start Tiller
run     Start Tiller and run arbitrary command within the environment
stop    Stop Tiller
```

Start Tiller:

```shell
$ helm tiller start
```

The default working Tiller `namespace` is `kube-system`, you can set another one:

```shell
$ helm tiller start my_tiller_namespace
```

> **Tip**: You can have many Tiller namespaces, e.g. one per team, just pass the name as an argument when you starting Tiller.

Example use of `tiller run`, that starts/stops `tiller` before/after the specified command:

```shell
$ helm tiller run helm list
$ helm tiller run my_tiller_namespace -- helm list
$ helm tiller run my_tiller_namespace -- bash -c 'echo running helm; helm list'
```

Stop Tiller:

```shell
$ helm tiller stop
```
