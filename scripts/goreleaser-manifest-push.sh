#!/usr/bin/env bash

image=$1
IFS=' ' read -r -a manifest_tags <<< "$2"

for tag in "${manifest_tags[@]}"; do
    docker manifest push "${image}:$tag"
done
