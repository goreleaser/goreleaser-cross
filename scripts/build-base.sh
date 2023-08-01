#!/usr/bin/env bash

set -e

arch=$1
image=$2
buildargs=$3

# shellcheck disable=SC2016
dockerfile=$(sed 's/goreleaser-cross-toolchains:.*/goreleaser-cross-toolchains:\$TOOLCHAINS_VERSION-\$TARGETARCH/' < Dockerfile.base)

docker build --platform=linux/"${arch}" -t "${image}" \
$buildargs \
. -f- <<EOF
$dockerfile
EOF
