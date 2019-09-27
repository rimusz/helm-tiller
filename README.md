# Tillerless Helm v2 plugin

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![CircleCI](https://circleci.com/gh/rimusz/helm-tiller/tree/master.svg?style=svg)](https://circleci.com/gh/rimusz/helm-tiller/tree/master)
[![Release](https://img.shields.io/github/release/rimusz/helm-tiller.svg?style=flat-square)](https://github.com/rimusz/helm-tiller/releases/latest)

[Helm](https://helm.sh) v2 plugin for using [Tiller](https://docs.helm.sh/using_helm/#installing-tiller) locally and in your CI/CD pipelines.

Blog post [Tillerless Helm v2](https://rimusz.net/tillerless-helm/) on why `Tillerless Helm` is needed and what it solves.

Check it out my new blog post [How to migrate from Helm v2 to Helm v3](https://rimusz.net/how-to-migrate-from-helm-v2-to-helm-v3) about migration from Helm v2 to Helm v3.

## Installation

Install Helm client as per one of recommended [ways](https://docs.helm.sh/using_helm/#installing-the-helm-client).

**Note:** Initialize helm with `helm init --client-only`, flag `--client-only` is a must as otherwise you will get `Tiller` installed in to Kubernetes cluster.

Then install the latest plugin version:

```console
helm plugin install https://github.com/rimusz/helm-tiller
```

## Usage

**Note:** For a better security Tiller plugin comes with preset storage as `Secret`.

Usage:

```console
helm tiller install
helm tiller start [tiller_namespace]
helm tiller start-ci [tiller_namespace]
helm tiller stop
helm tiller run [tiller_namespace] -- [command] [args]

Available Commands:
install   Manually install/upgrade Tiller binary
start     Start Tiller and open new pre-set shell
start-ci  Start Tiller without opening new shell
run       Start Tiller and run arbitrary command within the environment
stop      Stop Tiller
```

Available environment variables:

- To silence plugin specific messages by setting `HELM_TILLER_SILENT=true`, only `helm` cli output will be printed.
- To change default Tiller port by setting `HELM_TILLER_PORT=44140`, default is `44134`.
- To change default Tiller probe port by setting `HELM_TILLER_PROBE_PORT=44141`, default is `44135` - requires Helm >= 2.14.
- To change Tiller storage to `configmap` by setting `HELM_TILLER_STORAGE=configmap`, default is `secret`.
- To store Tiller logs in `$HOME/.helm/plugins/helm-tiller/logs` by setting `HELM_TILLER_LOGS=true`.
- You can set a specific folder/file for Tiller logs by setting `HELM_TILLER_LOGS_DIR=/some_folder/tiller.logs`.
- To change default Tiller maximum number of releases kept in release history by setting e.g. to 20 `HELM_TILLER_HISTORY_MAX=20`.
- To not automatically create a namespace if it is missing by setting `CREATE_NAMESPACE_IF_MISSING=false`.

### Tiller start examples

Start Tiller with pre-set `bash` shell `HELM_HOST=127.0.0.1:44134`, it is handy to use locally:

```console
helm tiller start
```

The default working Tiller `namespace` is `kube-system`, you can set another one:

```console
helm tiller start my_tiller_namespace
```

> **Tip**: You can have many Tiller namespaces, e.g. one per team, just pass the name as an argument when you starting Tiller.

In CI pipelines you do not really need pre-set bash to be opened, so you can use:

```console
helm tiller start-ci
export HELM_HOST=127.0.0.1:44134
```

Then your `helm` will know where to connect to Tiller and you do not need to make any changes in your CI pipelines.

And when you done stop the Tiller:

```console
helm tiller stop
```

### Tiller run examples

Another option for CI workflows.

Examples use of `tiller run`, that starts/stops `tiller` before/after the specified command:

```console
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

```console
# helm tiller run helm list
hh ls

# helm tiller run my-tiller-namespace -- helm list
hr my-tiller-namespace -- helm list

# helm tiller run my-tiller-namespace -- bash -c 'echo running helm; helm list'
hr my-tiller-namespace -- bash -c 'echo running helm; helm list'
```

### Terraform Tiller examples
To use tiller with [terraform-helm-provider](https://www.terraform.io/docs/providers/helm/index.html), use `helm tiller start-ci` and set the helm provider's host to point to the locally started tiller.

```console
$ helm tiller start-ci
```

```hcl
provider "helm" {
  host = "127.0.0.1:44134"
  install_tiller = false
}
```

This will greatly simplify your usage of `terraform-helm-provider` as there is no longer a need to create service accounts, and deploy tiller along with the problems that come with it.

### Using Tiller with Minikube
While using [Minikube](https://kubernetes.io/docs/setup/minikube/), it is important to stop, and restart tiller after a `minikube delete` and `minikube start`.

```console
$ minikube delete
$ minikube start
$ helm tiller stop
$ helm tiller start
```
