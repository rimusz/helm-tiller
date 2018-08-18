TILLER_VERSION ?= 2.10.0
TILLER_DOCKER_REGISTRY ?= gcr.io/kubernetes-helm/tiller
GCS_BUCKET ?= helm-tiller

.PHONY: build
build:
	$(eval export TILLER_VERSION)
	$(eval export TILLER_DOCKER_REGISTRY)
	$(eval export GCS_BUCKET)
	scripts/build.sh

.PHONY: build-patch
build-patch:
	$(eval export TILLER_VERSION)
	$(eval export TILLER_DOCKER_REGISTRY)
	$(eval export GCS_BUCKET)
	scripts/build-patch.sh
