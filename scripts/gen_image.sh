#!/bin/zsh

# Generate the Docker image

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

start_docker

# Pick the newest Ubuntu base image officially supported by that Vivado release:
#   2019.2        -> 18.04 (16.04 is older and not used)
#   2021.1-2022.1 -> 20.04
#   2022.2-2024.1 -> 22.04
#   2024.2+       -> 24.04
# Override with VIVADO_BASE_IMAGE or VIVADO_DOCKERFILE.
# Override with VIVADO_DOCKERFILE=/path/to/Dockerfile or VIVADO_BASE_IMAGE.
base_image="${VIVADO_BASE_IMAGE:-}"
if [ -z "$base_image" ]
then
	case "${VIVADO_VERSION:-}" in
	"")
		base_image="ubuntu:22.04"
		;;
	*)
		if [ "$VIVADO_VERSION" = "201920" ] 2>/dev/null
		then
			base_image="ubuntu:18.04"
		elif [ "$VIVADO_VERSION" -lt 202220 ] 2>/dev/null
		then
			base_image="ubuntu:20.04"
		elif [ "$VIVADO_VERSION" -lt 202420 ] 2>/dev/null
		then
			base_image="ubuntu:22.04"
		else
			base_image="ubuntu:24.04"
		fi
		;;
	esac
fi
dockerfile="${VIVADO_DOCKERFILE:-$script_dir/Dockerfile}"
f_echo "Using Dockerfile: $dockerfile (base image: $base_image)"

# Build the Docker image according to the Dockerfile
f_echo "Building Docker image..."
if ! docker build --platform linux/amd64 -f "$dockerfile" --build-arg BASE_IMAGE="$base_image" -t x64-linux "$script_dir"
then
	f_echo "Docker image generation failed!"
	exit 1
fi

f_echo "The Docker image was successfully generated."