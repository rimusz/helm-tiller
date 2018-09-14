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
$ helm tiller start-ci [tiller_namespace]
$ helm tiller stop
$ helm tiller run [tiller_namespace] -- [command] [args]
```

Available commands:

```
start     Start Tiller
start-ci  Start Tiller without opening new bash shell
run       Start Tiller and run arbitrary command within the environment
stop      Stop Tiller
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

Handy `bash` aliases for use locally:

```
alias hh="helm tiller run helm"
alias hr="helm tiller run"
alias ht="helm tiller start"
alias hts="helm tiller stop"
```

Examples of alias use:

```shell
# helm tiller run helm list
$ hh ls

# helm tiller run my-tiller-namespace -- helm list
$ hr my-tiller-namespace -- helm list

# helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'
$ hr my-tiller-namespace -- bash -c 'echo running helm; helm list'
```

## Tiller binaries

### Build/retrieve Tiller binaries and publish them

To build `MacOS` and to retrieve `Linux` binaries and then publish them to `GCS` bucket run on your Mac:

```shell
$ TILLER_VERSION=2.10.0 GCS_BUCKET=my_bucket make build
```

### Build patched Tiller binaries and publish them

**Note:** `Tiller`in pre `v2.10` does not support kubeconfig files which use user authentication via `auth-provider`, so you need to use this approach for all pre `v2.10` `tiller` releases.

To build patched `MacOS` and `Linux` `tiller` binaries and then publish them to `GCS` bucket run on your Mac:

```shell
$ TILLER_VERSION=2.9.1 GCS_BUCKET=my_bucket make build-patch
```
