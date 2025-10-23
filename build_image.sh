#!/usr/bin/env bash

# Prompt for missing environment variables
prompt_var() {
	local var="$1"
	local prompt="$2"
	if [ -z "${!var}" ]; then
		read -rp "$prompt: " val
		export "$var"="$val"
	fi
}

DEFAULT_UBUNTU_VERSION=24.04
DEFAULT_NODE_VERSION=22.19.0
DEFAULT_TEMPLATE_VERSION=1.3.2

# Default values (match the examples shown to allow Continue with Enter)
: ${UBUNTU_VERSION:=$DEFAULT_UBUNTU_VERSION}
: ${NODE_VERSION:=$DEFAULT_NODE_VERSION}
: ${TEMPLATE_VERSION:=$DEFAULT_TEMPLATE_VERSION}

# Prompt for values but show the default and accept Enter to keep it.
prompt_var() {
	local var="$1"
	local prompt="$2"
	# current value (may come from env or defaults above)
	local current="${!var}"
	read -rp "$prompt [$current]: " val
	if [ -n "$val" ]; then
		export "$var"="$val"
	else
		export "$var"="$current"
	fi
}

prompt_var UBUNTU_VERSION "Enter Ubuntu version"
prompt_var NODE_VERSION "Enter Node version"
prompt_var TEMPLATE_VERSION "Enter template version"

red="\033[0;31m"
cyan="\033[0;36m"
reset="\033[0m"

echo_error() {
	echo -e "${red}Error: $1${reset}"
	exit 1
}

echo_highlight() {
	echo -e "${cyan}$1${reset}"
}

# Show the values to be used
echo_highlight "The following values will be used to build the image:"
echo "  UBUNTU_VERSION:    $UBUNTU_VERSION"
echo "  NODE_VERSION:      $NODE_VERSION"
echo "  TEMPLATE_VERSION:  $TEMPLATE_VERSION"
echo

read -rp "Proceed with these values? [Y/n]: " confirm
if [[ ! (-z "$confirm" || "$confirm" =~ ^[Yy]$) ]]; then
	echo_error "Aborted. To avoid prompts, export the required environment variables before running this script:"
	echo "  export UBUNTU_VERSION=$DEFAULT_UBUNTU_VERSION"
	echo "  export NODE_VERSION=$DEFAULT_NODE_VERSION"
	echo "  export TEMPLATE_VERSION=$DEFAULT_TEMPLATE_VERSION"
	exit 1
fi

# --- Tag Generation ---
# Define components
readonly REGISTRY_USER="emboldcreative"
readonly IMAGE_NAME="base"

# Define version suffixes
readonly VERSION_SUFFIX="ubuntu${UBUNTU_VERSION}"
readonly RELEASE_SUFFIX="${VERSION_SUFFIX}-release${TEMPLATE_VERSION}"

# Define final, full image tags
readonly GENERAL_TAG="${REGISTRY_USER}/${IMAGE_NAME}:${VERSION_SUFFIX}"
readonly RELEASE_TAG="${REGISTRY_USER}/${IMAGE_NAME}:${RELEASE_SUFFIX}"

# Build the image
DOCKER_BUILDKIT=1 docker build -t "$RELEASE_TAG" \
	--build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
	--build-arg NODE_VERSION=${NODE_VERSION} \
	./

# Check if the build was successful
if [ $? -ne 0 ]; then
	echo_error "Build failed. Please check the output for errors."
	exit 1
fi

# Add additional tags for easier reference
docker tag "$RELEASE_TAG" "$GENERAL_TAG"

echo "Image built with tags:"
echo "  $RELEASE_TAG"
echo "  $GENERAL_TAG"
echo
echo "To push all tags, run:"
echo_highlight "  docker push $RELEASE_TAG"
echo_highlight "  docker push $GENERAL_TAG"

read -rp "Do you want to push all tags now? [y/N]: " push_answer
if [[ "$push_answer" =~ ^[Yy]$ ]]; then
	echo "Pushing all tags..."
	docker push "$RELEASE_TAG"
	docker push "$GENERAL_TAG"
	echo "All tags pushed successfully!"
fi
