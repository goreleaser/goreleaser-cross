#!/usr/bin/env bash

# VAR="goreleaser/goreleaser-cross:latest
# goreleaser/goreleaser-cross:v1.19.3-v1.12.3
# goreleaser/goreleaser-cross:v1.19-v1.12.3
# goreleaser/goreleaser-cross:v1.19
# goreleaser/goreleaser-cross:v1.19.3
# ghcr.io/goreleaser/goreleaser-cross:latest
# ghcr.io/goreleaser/goreleaser-cross:v1.19.3-v1.12.3
# ghcr.io/goreleaser/goreleaser-cross:v1.19-v1.12.3
# ghcr.io/goreleaser/goreleaser-cross:v1.19
# ghcr.io/goreleaser/goreleaser-cross:v1.19.3"

export COSIGN_PRIVATE_KEY="-----BEGIN ENCRYPTED COSIGN PRIVATE KEY-----
eyJrZGYiOnsibmFtZSI6InNjcnlwdCIsInBhcmFtcyI6eyJOIjozMjc2OCwiciI6
OCwicCI6MX0sInNhbHQiOiJEN3Zrd1g2WkNQd1FoMUlqSWJuU2FGUGN2eGRKZFAx
UkNxcklCQ1dKZkxvPSJ9LCJjaXBoZXIiOnsibmFtZSI6Im5hY2wvc2VjcmV0Ym94
Iiwibm9uY2UiOiJsYUpEN1ltdzlBZlBHczd6ck9mNTI2NXlYSXhCa3VUWSJ9LCJj
aXBoZXJ0ZXh0IjoiTWc5TGhJbDMxWVF2Vy9HV21GMkh2VkczWHRmZ09URTg5RDJZ
aXdtS1kvQncxczFSOWVLZGx6TU1OcUNYYVZUa01INkpWWEpYMTJPczNLQXJzMy9J
cG9DZHNQUVMveVl6eEVkRkNtMHkvYlUvNy9UaG1xZDV0N0p0NUtUbk9XSFRDOU4w
TXR3ZTB2NDErVlpWVWdLSWtaQ3oxaFZoZmw5SjdMY2lnVEE4dWlYSkMvUGtCb1FP
WmVBdXdGV1V5RXJaUWZjRURhN1pyQ3dYYmc9PSJ9
-----END ENCRYPTED COSIGN PRIVATE KEY-----
"

export COSIGN_PASSWORD="EobEPyGC6rZ2*mg7"

# VAR="ghcr.io/goreleaser/goreleaser-cross:v1.17.6
# ghcr.io/goreleaser/goreleaser-cross:v1.18.3
# ghcr.io/goreleaser/goreleaser-cross:v1.19.2
# ghcr.io/goreleaser/goreleaser-cross:v1.19.3-amd64
# ghcr.io/goreleaser/goreleaser-cross:v1.19.3-arm64
# ghcr.io/ovrclk/akash:0.16.3
# ghcr.io/ovrclk/akash:0.18.0-rc0-amd64
# ghcr.io/ovrclk/akash:0.18.0-rc0-arm64
# ghcr.io/ovrclk/akash:1324f29f-amd64
# ghcr.io/ovrclk/akash:1324f29f-arm64
# ghcr.io/ovrclk/akash:adcc6adf
# ghcr.io/ovrclk/akash:latest-amd64
# ghcr.io/ovrclk/akash:latest-arm64
# ghcr.io/ovrclk/akash:stable
# ghcr.io/ovrclk/provider-services:latest-arm64
# ghcr.io/troian/pihole:2022.10-arm64v8
# ghcr.io/troian/pihole:latest
# ghcr.io/troian/pihole:latest-arm64v8"

set -x

VAR="ghcr.io/goreleaser/goreleaser-cross:v1.18.3"

while IFS=$'\n' read -r line; do
    base_name=$(echo "$line" | cut -d ":" -f 1)
    id=$(docker image inspect "$line" --format='{{.Id}}')

    cosign sign --upload=false --key env://COSIGN_PRIVATE_KEY --recursive $base_name@$id
done <<< "${VAR}"

