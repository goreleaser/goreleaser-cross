#!/usr/bin/env bash

set -x

arch=$1
image=$2

docker build --platform=linux/${arch} -t ${image} \
$3 \
. -f- <<EOF
$(cat Dockerfile |  sed 's/goreleaser-cross-base:v\$GO_VERSION/goreleaser-cross-base:v\$GO_VERSION-\$TARGETARCH/')
EOF
