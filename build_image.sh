#!/usr/bin/env bash

# Stop script on first error
set -e

# --- Configuration ---
REGISTRY_HOST="ghcr.io"
REGISTRY_USER="emboldagency"
IMAGE_NAME="docker-base"
DEFAULT_OS_TYPE="ubuntu"
DEFAULT_UBUNTU="24.04"
DEFAULT_ALPINE="3.20"

# --- Helper Functions ---
cyan="\033[0;36m"
green="\033[0;32m"
reset="\033[0m"

echo_info() { echo -e "${cyan}$1${reset}"; }
echo_success() { echo -e "${green}$1${reset}"; }

prompt_var() {
	local var="$1"
	local prompt="$2"
	local default="$3"

	# If env var is already set, use it
	if [ -n "${!var}" ]; then return; fi

	read -rp "$prompt [$default]: " val
	if [ -z "$val" ]; then
		export "$var"="$default"
	else
		export "$var"="$val"
	fi
}

# --- Main Script ---

echo_info "--- Local Docker Build Helper ---"

# Gather Inputs
prompt_var OS_TYPE "Enter OS Type (ubuntu/alpine)" "$DEFAULT_OS_TYPE"

if [[ "$OS_TYPE" == "alpine" ]]; then
	echo_info "Note: Alpine support is not finished yet."
	prompt_var ALPINE_VERSION "Enter Alpine version" "$DEFAULT_ALPINE"
	OS_TAG="alpine${ALPINE_VERSION}"
	DOCKERFILE_PATH="./Dockerfile.alpine"
else
	prompt_var UBUNTU_VERSION "Enter Ubuntu version" "$DEFAULT_UBUNTU"
	OS_TAG="ubuntu${UBUNTU_VERSION}"
	DOCKERFILE_PATH="./Dockerfile"
fi

prompt_var TAG_SUFFIX "Enter tag suffix segment (optional)" ""

# Construct the Tag
if [ -n "$TAG_SUFFIX" ]; then
	FULL_IMAGE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${OS_TAG}-${TAG_SUFFIX}"
	TAG_SUFFIX_ARG="-${TAG_SUFFIX}"
else
	FULL_IMAGE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${OS_TAG}"
	TAG_SUFFIX_ARG=""
fi

echo
echo "Building Image:"
echo "  TAG:     $FULL_IMAGE_TAG"
echo "  OS:      $OS_TYPE ($OS_TAG)"
echo "  FILE:    $DOCKERFILE_PATH"
echo

# Build
if [ ! -f "$DOCKERFILE_PATH" ]; then
	echo "Error: Dockerfile not found at $DOCKERFILE_PATH"
	exit 1
fi

# Build arguments differ slightly based on OS
if [[ "$OS_TYPE" == "alpine" ]]; then
	DOCKER_BUILDKIT=1 docker build -t "$FULL_IMAGE_TAG" \
		-f "$DOCKERFILE_PATH" \
		--build-arg ALPINE_VERSION="${ALPINE_VERSION}" \
		--build-arg TAG_SUFFIX="${TAG_SUFFIX_ARG}" \
		./
else
	DOCKER_BUILDKIT=1 docker build -t "$FULL_IMAGE_TAG" \
		-f "$DOCKERFILE_PATH" \
		--build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
		--build-arg TAG_SUFFIX="${TAG_SUFFIX_ARG}" \
		./
fi

echo
echo_success "Build Complete!"
echo "To run this image interactively:"
if [[ "$OS_TYPE" == "alpine" ]]; then
	echo "  docker run --rm -it --entrypoint /bin/zsh $FULL_IMAGE_TAG"
else
	echo "  docker run --rm -it --entrypoint /bin/bash $FULL_IMAGE_TAG"
fi
echo

# Optional Push
read -rp "Do you want to push '$FULL_IMAGE_TAG' to GHCR? [y/N]: " push_confirm
if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
	echo_info "Pushing..."
	docker push "$FULL_IMAGE_TAG"
	echo_success "Pushed successfully."
else
	echo "Skipping push."
fi
