# Tillerless Helm plugin

[Helm](https://helm.sh) plugin for using [Tiller](https://docs.helm.sh/using_helm/#installing-tiller) locally and in your CI/CD pipelines.

My blog [post](https://rimusz.net/tillerless-helm/) on why `Tilless Helm` is needed and what it solves.

**Note:** For a better security Tiller plugin comes with preset storage as `Secret`.

## Installation

Install the latest version:

```shell
helm plugin install https://github.com/rimusz/helm-tiller
```

## Usage

Usage:

```shell
helm tiller install
helm tiller start [tiller_namespace]
helm tiller start-ci [tiller_namespace] (without new bash shell)
helm tiller stop
helm tiller run [tiller_namespace] -- [command] [args]
```

Available commands:

```
install   Manually install/upgrade Tiller binary
start     Start Tiller
start-ci  Start Tiller without opening new bash shell
run       Start Tiller and run arbitrary command within the environment
stop      Stop Tiller
```

### Tiller start examples

Start Tiller with pre-set `bash` shell `HELM_HOST=localhost:44134`, it is handy to use locally:

```shell
helm tiller start
```

The default working Tiller `namespace` is `kube-system`, you can set another one:

```shell
$ helm tiller start my_tiller_namespace
```

> **Tip**: You can have many Tiller namespaces, e.g. one per team, just pass the name as an argument when you starting Tiller.

In CI pipelines you do not really need pre-set bash to be opened, so you can use:

```shell
helm tiller start-ci
export HELM_HOST=localhost:44134
```

Then your `helm` will know where to connect to Tiller and you do not need to make any changes in your CI pipelines.

And when you done stop the Tiller:

```shell
helm tiller stop
```

### Tiller run examples

Another option for CI workflows.

Examples use of `tiller run`, that starts/stops `tiller` before/after the specified command:

```shell
helm tiller run helm list
helm tiller run my-tiller-namespace -- helm list
helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'
```

Handy `bash` aliases for use `Tillerless` locally:

```
alias hh="helm tiller run helm"
alias hr="helm tiller run"
alias ht="helm tiller start"
alias hts="helm tiller stop"
```

Examples of alias use:

```shell
# helm tiller run helm list
hh ls

# helm tiller run my-tiller-namespace -- helm list
hr my-tiller-namespace -- helm list

# helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'
hr my-tiller-namespace -- bash -c 'echo running helm; helm list'
```

## Tiller binaries

### Tiller binaries for v2.11 Helm and above versions

Beginning of Helm v2.11 release, `helm` archive file comes packed with `tiller` binary as well.
Plugin will check the version and download the right archive file. No more building/retrieving of
`tiller` binary is needed anymore.

### Build/retrieve Tiller binaries and publish them for v2.10 Helm

To build `MacOS` and to retrieve `Linux` binaries and then publish them to `GCS` bucket run on your Mac:

```shell
TILLER_VERSION=2.10.0 GCS_BUCKET=my_bucket make build
```

### Build patched Tiller binaries and publish them for pre v2.10 Helm

**Note:** `Tiller`in pre `v2.10` does not support kubeconfig files which use user authentication via `auth-provider`, so you need to use this approach for all pre `v2.10` `tiller` releases.

To build patched `MacOS` and `Linux` `tiller` binaries and then publish them to `GCS` bucket run on your Mac:

```shell
TILLER_VERSION=2.9.1 GCS_BUCKET=my_bucket make build-patch
```
