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

## Tiller binaries

### Build patched Tiller binaries and publish them

**Note:** Currently `tiller` does not support `kubeconfig` files which use user authentication via `auth-provider`.
There is `tiller` PR [#4426](https://github.com/helm/helm/pull/4426) which hopefully will be merged soon and new `tiller`
version `2.10` will not be needed to be patched anymore.

To build patched `MacOS` and `Linux` `tiller` binaries and then publish them to `GCS` bucket run on your Mac:

```shell
$ TILLER_VERSION=2.9.1 GCS_BUCKET=my_bucket make build-patch
```

**Note:** Also you still need to use this approach for all pre `v2.10` `tiller` releases.

### Build/retrieve Tiller binaries and publish them

To build `MacOS` and to retrieve `Linux` binaries and then publish them to `GCS` bucket run on your Mac:

```shell
$ TILLER_VERSION=2.9.1 GCS_BUCKET=my_bucket make build
```
