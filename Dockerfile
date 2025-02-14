# golang parameters
ARG GORELEASER_VERSION
ARG GORELEASER_DISTRIBUTION=""
ARG BASE_VERSION=latest

FROM ghcr.io/goreleaser/goreleaser$GORELEASER_DISTRIBUTION:v$GORELEASER_VERSION AS goreleaser

FROM ghcr.io/goreleaser/goreleaser-cross-base:$BASE_VERSION

LABEL maintainer="Artur Troian <troian dot ap at gmail dot com>"
LABEL "org.opencontainers.image.source"="https://github.com/goreleaser/goreleaser-cross"

COPY --from=goreleaser /usr/bin/goreleaser /usr/bin/goreleaser
