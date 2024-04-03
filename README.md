# docker-base

Coder v2 Ubuntu docker base image

```
# Set the base image version
export UBUNTU_VERSION=22.04

# Build the image
docker build -t emboldcreative/base:ubuntu${UBUNTU_VERSION} --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} .

# Push the image to the registry
docker push emboldcreative/base:ubuntu${UBUNTU_VERSION}
```
