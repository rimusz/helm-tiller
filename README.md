# Tillerless Helm plugin

[Helm](https://helm.sh) plugin for using [Tiller](https://docs.helm.sh/using_helm/#installing-tiller) locally and in your CI/CD pipelines.

**Note:** For a better security Tiller plugin comes with preset storage as `Secret`.

## Installation

Install the latest version:

```shell
$ helm plugin install https://github.com/rimusz/helm-tiller
```

## Usage

Usage:

```shell
$ helm tiller start [tiller_namespace]
$ helm tiller stop
$ helm tiller run [tiller_namespace] -- [command] [args]
```

Available commands:

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

Examples use of `tiller run`, that starts/stops `tiller` before/after the specified command:

```shell
$ helm tiller run helm list
$ helm tiller run my-tiller-namespace -- helm list
$ helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'
```

Stop Tiller:

```shell
$ helm tiller stop
```

## Build and publish Tiller binaries

To build `MacOS` and to retrieve `Linux` binaries and then publish them to `GCS` bucket:

```shell
$ TILLER_VERSION=2.9.1 GCS_BUCKET=my_bucket make build
```
