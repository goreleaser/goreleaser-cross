include .env

BASH_PATH          := $(shell which bash)
SHELL              := $(BASH_PATH)

export GORELEASER_VERSION

PHONY: release-dryrun
release-dryrun:
	@echo "building base image"
	goreleaser release -f .goreleaser.yaml --clean --parallelism=1 --skip=publish,validate --snapshot


PHONY: release
release:
	@echo "building base image"
	goreleaser release -f .goreleaser.yaml --clean --parallelism=1
