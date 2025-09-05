# Contributing

To build and publish all images, run:

```sh
direnv allow .
make release-base release-goreleaser release-goreleaserpro
```

## Direnv

Make sure direnv is set up to load from `.env` directly (it's disabled by
default in recent versions).
