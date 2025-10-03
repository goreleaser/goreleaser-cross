include .env

BASH_PATH          := $(shell which bash)
SHELL              := $(BASH_PATH)

TAGS_SCRIPT        := ./scripts/image-tags.sh

TAG_VERSION        ?= $(shell git describe --tags --abbrev=0)

export GORELEASER_VERSION

REGISTRIES          ?= docker.io \
ghcr.io

SUBIMAGES ?= arm64 \
amd64

IMAGE_BASE_NAMES    := $(shell $(TAGS_SCRIPT) cross-base "$(TAG_VERSION)" "$(REGISTRIES)")
IMAGE_NAMES         := $(shell $(TAGS_SCRIPT) cross "$(TAG_VERSION)" "$(REGISTRIES)")
IMAGE_PRO_NAMES     := $(shell $(TAGS_SCRIPT) cross-pro "$(TAG_VERSION)" "$(REGISTRIES)")

IMAGE_BASE_TAGS     := $(foreach ARCH,$(SUBIMAGES),$(foreach IMAGE,$(IMAGE_BASE_NAMES), $(IMAGE)-$(ARCH)))
IMAGE_TAGS          := $(foreach ARCH,$(SUBIMAGES),$(foreach IMAGE,$(IMAGE_NAMES), $(IMAGE)-$(ARCH)))
IMAGE_PRO_TAGS      := $(foreach ARCH,$(SUBIMAGES),$(foreach IMAGE,$(IMAGE_PRO_NAMES), $(IMAGE)-$(ARCH)))

define cross_base_tags
	$(shell $(TAGS_SCRIPT) cross-base "$(TAG_VERSION)" "$(1)")
endef

IMAGE_TOOLCHAINS   := goreleaser/goreleaser-cross-toolchains:$(TOOLCHAINS_VERSION)

ifneq ($(REGISTRY),)
	IMAGE_BASE_NAME    := $(REGISTRY)/$(IMAGE_BASE_NAME)
	IMAGE_NAME         := $(REGISTRY)/$(IMAGE_NAME)
	IMAGE_PRO_NAME     := $(REGISTRY)/$(IMAGE_PRO_NAME)
	IMAGE_TOOLCHAINS   := $(REGISTRY)/$(IMAGE_TOOLCHAINS)
endif

DOCKER_BUILD=docker build

.PHONY: gen-changelog
gen-changelog:
	@echo "generating changelog to changelog"
	./scripts/genchangelog.sh $(shell git describe --tags --abbrev=0) changelog.md

.PHONY: base-%
base-%:
	@echo "building $* version of base image"
	docker build --platform=linux/$* \
		$(foreach IMAGE,$(IMAGE_BASE_NAMES),-t $(IMAGE)-$*) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg TINI_VERSION=$(TINI_VERSION) \
		--build-arg COSIGN_VERSION=$(COSIGN_VERSION) \
		--build-arg DEBIAN_FRONTEND=$(DEBIAN_FRONTEND) \
		--build-arg TOOLCHAINS_TAG="$(TOOLCHAINS_VERSION)" \
		. -f Dockerfile.base

.PHONY: goreleaser-%
goreleaser-%:
	@echo "building $(IMAGE_NAME)-$*"
	docker build --platform=linux/$* \
		$(foreach IMAGE,$(IMAGE_NAMES),-t $(IMAGE)-$*) \
		--build-arg BASE_VERSION=$(TAG_VERSION)-$* \
		--build-arg GORELEASER_VERSION=$(GORELEASER_VERSION) \
		. -f Dockerfile

.PHONY: goreleaserpro-%
goreleaserpro-%:
	@echo "building $(IMAGE_PRO_NAME)-$*"
	docker build --platform=linux/$* \
		$(foreach IMAGE,$(IMAGE_PRO_NAMES),-t $(IMAGE)-$*) \
		--build-arg BASE_VERSION=$(TAG_VERSION)-$* \
		--build-arg GORELEASER_VERSION=$(GORELEASER_VERSION) \
		--build-arg GORELEASER_DISTRIBUTION=-pro \
		. -f Dockerfile

.PHONY: base
base: $(patsubst %, base-%,$(SUBIMAGES))

.PHONY: goreleaser
goreleaser: $(patsubst %, goreleaser-%,$(SUBIMAGES))

.PHONY: goreleaserpro
goreleaserpro: $(patsubst %, goreleaserpro-%,$(SUBIMAGES))

.PHONY: docker-push-base
docker-push-base:
	@$(foreach IMAGE, $(IMAGE_BASE_TAGS), docker push $(IMAGE);)

.PHONY: docker-push
docker-push:
	@$(foreach IMAGE, $(IMAGE_TAGS), docker push $(IMAGE);)

.PHONY: docker-pushpro
docker-pushpro:
	@$(foreach IMAGE, $(IMAGE_PRO_TAGS), docker push $(IMAGE);)

.PHONY: pull-toolchain-%
pull-toolchain-%:
	@echo "pulling toolchain $(IMAGE_TOOLCHAINS)-$(@:pull-toolchain-%=%)"
	docker pull --platform=linux/$(@:pull-toolchain-%=%) $(IMAGE_TOOLCHAINS)
	docker tag $(IMAGE_TOOLCHAINS) $(IMAGE_TOOLCHAINS)-$(@:pull-toolchain-%=%)

.PHONY: pull-toolchains
pull-toolchains: $(patsubst %, pull-toolchain-%,$(SUBIMAGES))

.PHONY: manifest-create-base
manifest-create-base:
	@echo "creating base manifests"
	@$(foreach IMAGE, $(IMAGE_BASE_NAMES), docker manifest rm $(IMAGE) 2>/dev/null || true;)
	@$(foreach IMAGE, $(IMAGE_BASE_NAMES), \
		docker manifest create $(IMAGE) $(foreach arch,$(SUBIMAGES),\
		$$(docker inspect $(IMAGE)-$(arch) | jq -r --arg image $$(echo $(IMAGE)-$(arch) | cut -d ':' -f 1) '.[].RepoDigests[] | select(. | startswith($$image))'));)

.PHONY: manifest-create
manifest-create:
	@echo "creating goreleaser manifests"
	@$(foreach IMAGE,$(IMAGE_NAMES),docker manifest rm $(IMAGE) 2>/dev/null || true;)
	@$(foreach IMAGE, $(IMAGE_NAMES), \
		docker manifest create $(IMAGE) $(foreach arch,$(SUBIMAGES), \
		$$(docker inspect $(IMAGE)-$(arch) | jq -r --arg image $$(echo $(IMAGE)-$(arch) | cut -d ':' -f 1) '.[].RepoDigests[] | select(. | startswith($$image))'));)

.PHONY: manifest-createpro
manifest-createpro:
	@echo "creating goreleaser pro manifests"
	@$(foreach IMAGE,$(IMAGE_PRO_NAMES),docker manifest rm $(IMAGE) 2>/dev/null || true;)
	@$(foreach IMAGE, $(IMAGE_PRO_NAMES), \
		docker manifest create $(IMAGE) $(foreach arch,$(SUBIMAGES), \
		$$(docker inspect $(IMAGE)-$(arch) | jq -r --arg image $$(echo $(IMAGE)-$(arch) | cut -d ':' -f 1) '.[].RepoDigests[] | select(. | startswith($$image))'));)

.PHONY: manifest-push-base
manifest-push-base:
	@echo "pushing base manifests"
	@$(foreach IMAGE,$(IMAGE_BASE_NAMES),docker manifest push $(IMAGE);)

.PHONY: manifest-push
manifest-push:
	@echo "pushing goreleaser manifests"
	@$(foreach IMAGE,$(IMAGE_NAMES),docker manifest push $(IMAGE);)

.PHONY: manifest-pushpro
manifest-pushpro:
	@echo "pushing goreleaser pro manifests"
	@$(foreach IMAGE,$(IMAGE_PRO_NAMES),docker manifest push $(IMAGE);)

.PHONY: release-base
release-base: base docker-push-base manifest-create-base manifest-push-base

.PHONY: release-goreleaser
release-goreleaser: goreleaser docker-push manifest-create manifest-push

.PHONY: release-goreleaserpro
release-goreleaserpro: goreleaserpro docker-pushpro manifest-createpro manifest-pushpro

.PHONY: tags
tags:
	@echo $(IMAGE_NAME) $(foreach arch,$(SUBIMAGES), $(IMAGE_NAME)-$(arch))

.PHONY: tag
tag:
	@echo $(TAG_VERSION)
