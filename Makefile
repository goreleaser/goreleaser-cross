GORELEASER_ARGS := --parallelism=1

ifeq (,$(findstring release,$(BUILDOPTS)))
	GORELEASER_ARGS += --skip=publish,validate --snapshot
endif

ifneq (,$(findstring verbose,$(BUILDOPTS)))
	GORELEASER_ARGS += --verbose
endif

.PHONY: release
release:
	goreleaser release -f .goreleaser.yaml --timeout=2h --clean $(GORELEASER_ARGS)
