#!/usr/bin/env bash

set -ex

arch=$1
images=$2
buildargs=$3

# shellcheck disable=SC2016
dockerfile=$(sed 's/goreleaser-cross-base:.*/goreleaser-cross-base:\$TAG_VERSION-\$TARGETARCH/' < Dockerfile)

# shellcheck disable=SC2086
docker build --platform=linux/"${arch}" $images \
$buildargs \
. -f- <<EOF
$dockerfile
EOF
