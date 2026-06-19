# Working on docker-base

Base image for Embold Coder workspaces. Downstream repos (`docker-php`, `docker-ruby`) build `FROM` this image.

## Layout

- `Dockerfile` — Ubuntu base (24.04)
- `Dockerfile.alpine` — Alpine variant
- `coder/` — scripts and conf files copied into `/coder` inside the image
- `build_image.sh` — local build helper; prompts for OS + version, optionally pushes to GHCR
- `.github/workflows/` — builds on tag push, push to `main`, and manual dispatch

## Conventions

- **Keep apt-get package lists alphabetized.** Recent commits have been re-alphabetizing; new additions go in alpha order.
- Dockerfile indentation uses tabs for line-continuation blocks.
- `EMBOLD_UID=1001` / `EMBOLD_GID=1001` are load-bearing — they're pinned so workspace home volumes keep consistent ownership across image rebuilds.

## Tagging

Images are tagged `ghcr.io/emboldagency/docker-base:ubuntu${UBUNTU_VERSION}` — **no template-version suffix**. This image is versioned only by OS; downstream repos carry their own VERSION for their tags.

## Release

1. Commit.
2. `git tag vYYYY.MM.DD.N && git push --tags` — the `v`-prefixed tag triggers GHA, which builds and pushes the OS-tagged image to GHCR.

The default branch is `main` (aligned with `docker-php`/`docker-ruby`). The workflow triggers on pushes to `main` (warms the build cache + refreshes the floating `ubuntu${UBUNTU_VERSION}` tag) and on `v*` tag pushes (builds and pushes the versioned image), plus `workflow_dispatch`.

See `README.md` for local build commands.
