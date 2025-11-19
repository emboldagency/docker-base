# docker-base

Coder v2 Ubuntu docker base image

# Build Process

## Automated Builds

GitHub Actions is configured to automatically build the base images when a new version tag is created on GitHub.

New tags will be pushed for each of the versions specified in the [docker-build workflow file](.github/workflows/docker-build.yml)

## Manual Builds

```bash
# Set the base image version
export UBUNTU_VERSION=24.04

# Build the image
docker build -t ghcr.io/emboldagency/base:ubuntu${UBUNTU_VERSION} --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} .

# Push the image to the registry
docker push ghcr.io/emboldagency/base:ubuntu${UBUNTU_VERSION}
```
