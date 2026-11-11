#!/bin/zsh

# Generate the Docker image

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

start_docker

# Vivado <= 2021.2 is only supported on Ubuntu <= 20.04, so use the legacy
# Dockerfile for those versions. Override with VIVADO_DOCKERFILE=/path/to/Dockerfile.
dockerfile="${VIVADO_DOCKERFILE:-}"
if [ -z "$dockerfile" ]
then
	case "${VIVADO_VERSION:-}" in
	2019*|2020*|2021*)
		dockerfile="$script_dir/Dockerfile.legacy"
		;;
	*)
		dockerfile="$script_dir/Dockerfile"
		;;
	esac
fi
f_echo "Using Dockerfile: $dockerfile"

# Build the Docker image according to the Dockerfile
f_echo "Building Docker image..."
if ! docker build --platform linux/amd64 -f "$dockerfile" -t x64-linux "$script_dir"
then
	f_echo "Docker image generation failed!"
	exit 1
fi

f_echo "The Docker image was successfully generated."