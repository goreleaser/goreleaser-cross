#!/usr/bin/env bash

set -e

if [[ -z "$GPG_KEY" ]]; then
	GPG_KEY=/secrets/key.gpg
fi

if [[ -f "${GPG_KEY}" ]]; then
	echo "importing gpg key..."
	if gpg --batch --import "${GPG_KEY}"; then
		gpg --list-secret-keys --keyid-format long
	fi
fi

if [[ -z "$DOCKER_CREDS_FILE" ]]; then
	DOCKER_CREDS_FILE=/secrets/.docker-creds
fi

if [[ -f $DOCKER_CREDS_FILE ]]; then
	if cat "$DOCKER_CREDS_FILE" | jq 2>&1 >/dev/null ; then
		while read user pass registry ; do
			echo "$pass" | docker login --username "$user" --password-stdin "$registry"
		done <<< $(cat "$DOCKER_CREDS_FILE" | jq -Mr '.registries[] | [.user, .pass, .registry] | @tsv')
	else
		IFS=':'
			while read -r user pass registry; do
				echo "$pass" | docker login -u "$user" --password-stdin "$registry"
			done <$DOCKER_CREDS_FILE
	fi
fi

exec goreleaser "$@"
