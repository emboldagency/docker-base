# docker-base

Coder v2 Ubuntu docker base image

# Build Process

## Automated Builds

GitHub Actions is configured to automatically build the base images when a new version tag is created on GitHub.

New tags will be pushed for each of the versions specified in the [docker-build workflow file](.github/workflows/docker-build.yml)

## Manual Builds

### Using the Build Script (Recommended)

For local development and testing, use the included helper script. It prompts for the Ubuntu version and optional tag suffix, then runs the build with the correct arguments.

```bash
./build_image.sh
```

### Using Docker CLI

Set the base image version

```bash
export UBUNTU_VERSION=24.04
```

Build the image

```bash
docker build -t ghcr.io/emboldagency/docker-base:ubuntu${UBUNTU_VERSION} --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} .
```

If you are pushing to GHCR, authenticate first.

- The username is the owner of the PAT.
- The password is in Bitwarden on the `GitHub (Alert/Staging)` entry as `GHCR Token (Write)`.

```bash
export GHCR_USER="emboldagency"
export GHCR_TOKEN="<your-ghcr-pat-with-packages-write>"
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
```

Push the image to the registry

```bash
docker push ghcr.io/emboldagency/docker-base:ubuntu${UBUNTU_VERSION}
```
