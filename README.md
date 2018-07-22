# Run Helm Tiller locally

[Helm](https://helm.sh) plugin for using [Tiller](https://docs.helm.sh/using_helm/#installing-tiller) locally.


## Installation

Install the latest version:

```shell
$ helm plugin install https://github.com/rimusz/helm-tiller
```

Install a specific version:

```shell
$ helm plugin install https://github.com/rimusz/helm-tiller --version 0.1.1
```

## Usage

Start Tiller:

```shell
$ helm tiller start
```

Start Tiller with the set namespace and storage Secret:

```shell
$ helm tiller start my_tiller_namespace secret
```

Stop Tiller:

```shell
$ helm tiller stop
```
