#!/usr/bin/env bash

set -x

arch=$1
image=$2

docker build --platform=linux/${arch} -t ${image} \
$3 \
. -f- <<EOF
$(cat Dockerfile.base |  sed 's/goreleaser-cross-toolchains:\$TOOLCHAINS_VERSION/goreleaser-cross-toolchains:\$TOOLCHAINS_VERSION-\$TARGETARCH/')
EOF
