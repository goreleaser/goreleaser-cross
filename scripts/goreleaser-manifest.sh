#!/usr/bin/env bash

version=$1
image=$2

image_ver="${image}:${version}"

IFS=' ' read -r -a manifest_tags <<< "$3"
IFS=' ' read -r -a subimages <<< "$4"

digests=()

for arch in "${subimages[@]}"; do
    digests+=("$(docker inspect "${image_ver}-${arch}" | jq -r '.[].RepoDigests | .[0]')")
done

for tag in "${manifest_tags[@]}"; do
    manifest=${image}:$tag
    docker manifest rm "$manifest" 2>/dev/null || true
    docker manifest create "$manifest" "${digests[@]}"
done
