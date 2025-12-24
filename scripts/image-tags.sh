#!/usr/bin/env bash

# in akash even minor part of the tag indicates release belongs to the MAINNET
# using it as scripts simplifies debugging as well as portability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

function generate_interim_tags {
	local hub="goreleaser/$1"
	local tag=$2
	local tag_minor
	local registries

	# shellcheck disable=SC2206
	registries=($3)

	tag_minor=v$("${SCRIPT_DIR}/semver.sh" get major "$tag").$("${SCRIPT_DIR}/semver.sh" get minor "$tag")

	for registry in "${registries[@]}"; do
		image=$hub
		if [[ "$registry" != "docker.io" ]]; then
			image=$registry/$image
		fi

		if [[ $("${SCRIPT_DIR}"/is_prerelease.sh "$tag") == true ]]; then
			echo "$image:$tag"
		else
			echo "$image:$tag"
			echo "$image:$tag_minor"
			echo "$image:latest"
		fi
	done

	exit 0
}

function generate_tags {
	local hub="goreleaser/$1"
	local tag=$2
	local GORELEASER_VERSION=v$GORELEASER_VERSION
	local tag_minor
	local registries

	# shellcheck disable=SC2206
	registries=($3)
	tag_minor=v$("${SCRIPT_DIR}/semver.sh" get major "$tag").$("${SCRIPT_DIR}/semver.sh" get minor "$tag")

	for registry in "${registries[@]}"; do
		image=$hub
		if [[ "$registry" != "docker.io" ]]; then
			image=$registry/$image
		fi

		if [[ $("${SCRIPT_DIR}"/is_prerelease.sh "$tag") == true ]]; then
			echo "$image:$tag-$GORELEASER_VERSION"
			echo "$image:$tag.$GORELEASER_VERSION"
			echo "$image:$tag"
		else
			echo "$image:$tag.$GORELEASER_VERSION"
			echo "$image:$tag-$GORELEASER_VERSION"
			echo "$image:$tag_minor.$GORELEASER_VERSION"
			echo "$image:$tag_minor-$GORELEASER_VERSION"
			echo "$image:$tag_minor"
			echo "$image:$tag"
			echo "$image:latest"
		fi
	done

	exit 0
}

case $1 in
	cross-base)
		generate_interim_tags "goreleaser-$1" "$2" "$3"
		;;
	cross|cross-pro)
		generate_tags "goreleaser-$1" "$2" "$3"
		;;
esac
