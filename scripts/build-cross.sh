#!/usr/bin/env bash

set -e

arch=$1
image=$2
buildargs=$3

# shellcheck disable=SC2016
dockerfile=$(sed 's/goreleaser-cross-base:.*/goreleaser-cross-base:\$TAG_VERSION-\$TARGETARCH/' < Dockerfile)

docker build --platform=linux/"${arch}" -t "${image}" \
$buildargs \
. -f- <<EOF
$dockerfile
EOF
