include .env

REGISTRY           ?= ghcr.io
TAG_VERSION        ?= $(shell git describe --tags --abbrev=0)

IMAGE_BASE_NAME    := goreleaser/goreleaser-cross-base:$(TAG_VERSION)
IMAGE_NAME         := goreleaser/goreleaser-cross:$(TAG_VERSION)
IMAGE_PRO_NAME     := goreleaser/goreleaser-cross-pro:$(TAG_VERSION)
IMAGE_TOOLCHAINS   := ghcr.io/goreleaser/goreleaser-cross-toolchains:$(TOOLCHAINS_VERSION)
ifneq ($(REGISTRY),)
	IMAGE_BASE_NAME    := $(REGISTRY)/goreleaser/goreleaser-cross-base:$(TAG_VERSION)
	IMAGE_NAME         := $(REGISTRY)/goreleaser/goreleaser-cross:$(TAG_VERSION)
	IMAGE_PRO_NAME     := $(REGISTRY)/goreleaser/goreleaser-cross-pro:$(TAG_VERSION)
	IMAGE_TOOLCHAINS   := $(REGISTRY)/ghcr.io/goreleaser/goreleaser-cross-toolchains:$(TOOLCHAINS_VERSION)
endif

DOCKER_BUILD=docker build

SUBIMAGES ?= arm64 \
amd64

.PHONY: gen-changelog
gen-changelog:
	@echo "generating changelog to changelog"
	./scripts/genchangelog.sh $(shell git describe --tags --abbrev=0) changelog.md

.PHONY: base-%
base-%:
	@echo "building $(IMAGE_BASE_NAME)-$(@:base-%=%)"
	./scripts/build-base.sh $(@:base-%=%) $(IMAGE_BASE_NAME)-$(@:base-%=%) \
		"--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg TINI_VERSION=$(TINI_VERSION) \
		--build-arg COSIGN_VERSION=$(COSIGN_VERSION) \
		--build-arg COSIGN_SHA256=$(COSIGN_SHA256) \
		--build-arg DEBIAN_FRONTEND=$(DEBIAN_FRONTEND) \
		--build-arg TOOLCHAINS_VERSION=$(TOOLCHAINS_VERSION)"

.PHONY: goreleaser-%
goreleaser-%:
	@echo "building $(IMAGE_NAME)-$(@:goreleaser-%=%)"
	./scripts/build-cross.sh $(@:goreleaser-%=%) \
		$(IMAGE_NAME)-$(@:goreleaser-%=%) \
		"--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg GORELEASER_VERSION=$(GORELEASER_VERSION)"

.PHONY: goreleaserpro-%
goreleaserpro-%:
	@echo "building $(IMAGE_PRO_NAME)-$(@:goreleaserpro-%=%)"
	./scripts/build-cross.sh $(@:goreleaserpro-%=%) \
		$(IMAGE_PRO_NAME)-$(@:goreleaserpro-%=%) \
		"--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg GORELEASER_VERSION=$(GORELEASER_VERSION) \
		--build-arg GORELEASER_DISTRIBUTION=-pro"

.PHONY: base
base: $(patsubst %, base-%,$(SUBIMAGES))

.PHONY: goreleaser
goreleaser: $(patsubst %, goreleaser-%,$(SUBIMAGES))

.PHONY: goreleaserpro
goreleaserpro: $(patsubst %, goreleaserpro-%,$(SUBIMAGES))

.PHONY: docker-push-base-%
docker-push-base-%:
	docker push $(IMAGE_BASE_NAME)-$(@:docker-push-base-%=%)

.PHONY: docker-push-%
docker-push-%:
	docker push $(IMAGE_NAME)-$(@:docker-push-%=%)

.PHONY: docker-pushpro-%
docker-pushpro-%:
	docker push $(IMAGE_PRO_NAME)-$(@:docker-pushpro-%=%)

.PHONY: docker-push-base
docker-push-base: $(patsubst %, docker-push-base-%,$(SUBIMAGES))

.PHONY: docker-push
docker-push: $(patsubst %, docker-push-%,$(SUBIMAGES))

.PHONY: docker-pushpro
docker-pushpro: $(patsubst %, docker-pushpro-%,$(SUBIMAGES))

.PHONY: pull-toolchain-%
pull-toolchain-%:
	@echo "pulling toolchain $(IMAGE_TOOLCHAINS)-$(@:pull-toolchain-%=%)"
	docker pull --platform=linux/$(@:pull-toolchain-%=%) $(IMAGE_TOOLCHAINS)
	docker tag $(IMAGE_TOOLCHAINS) $(IMAGE_TOOLCHAINS)-$(@:pull-toolchain-%=%)

.PHONY: pull-toolchains
pull-toolchains: $(patsubst %, pull-toolchain-%,$(SUBIMAGES))

.PHONY: manifest-create-base
manifest-create-base:
	@echo "creating base manifest $(IMAGE_BASE_NAME)"
	docker manifest create $(IMAGE_BASE_NAME) $(foreach arch,$(SUBIMAGES), --amend $(IMAGE_BASE_NAME)-$(arch))

.PHONY: manifest-create
manifest-create:
	@echo "creating manifest $(IMAGE_NAME)"
	docker manifest create $(IMAGE_NAME) $(foreach arch,$(SUBIMAGES), --amend $(IMAGE_NAME)-$(arch))

.PHONY: manifest-createpro
manifest-create-pro:
	@echo "creating manifest $(IMAGE_PRO_NAME)"
	docker manifest create $(IMAGE_PRO_NAME) $(foreach arch,$(SUBIMAGES), --amend $(IMAGE_PRO_NAME)-$(arch))

.PHONY: manifest-push-base
manifest-push-base:
	@echo "pushing base manifest $(IMAGE_BASE_NAME)"
	docker manifest push $(IMAGE_BASE_NAME)

.PHONY: manifest-push
manifest-push:
	@echo "pushing manifest $(IMAGE_NAME)"
	docker manifest push $(IMAGE_NAME)

.PHONY: manifest-pushpro
manifest-pushpro:
	@echo "pushing manifest $(IMAGE_PRO_NAME)"
	docker manifest push $(IMAGE_PRO_NAME)

.PHONY: tags
tags:
	@echo $(IMAGE_NAME) $(foreach arch,$(SUBIMAGES), $(IMAGE_NAME)-$(arch))

.PHONY: tag
tag:
	@echo $(TAG_VERSION)
