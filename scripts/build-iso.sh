#!/bin/bash
# builds an ISO based on an OCI with an embeded config
# args:
# - image: the image to build the ISO from
# - config: the config.yaml file to use

set -e  # Exit on any error

IMAGE=$1
CONFIG=$2
# Validate arguments
if [ -z "$IMAGE" ]; then
    echo "Error: IMAGE argument is required"
    echo "Usage: $0 <image> <config.yaml> [--extend]"
    exit 1
fi

if [ -z "$CONFIG" ]; then
    echo "Error: CONFIG argument is required"
    echo "Usage: $0 <image> <config.yaml> [--extend]"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG" ]; then
    echo "Error: Config file '$CONFIG' not found"
    exit 1
fi

# Convert to absolute path if relative
CONFIG_ABS=$(realpath "$CONFIG")
echo "Using config file: $CONFIG_ABS"
echo "Using image: $IMAGE"

mkdir -p build

# Check if podman socket exists
if [ ! -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
    echo "Error: Podman socket not found at $XDG_RUNTIME_DIR/podman/podman.sock"
    echo "Make sure podman is running with: systemctl --user start podman.socket"
    exit 1
fi

echo "Starting auroraboot to build ISO..."

# Get podman storage path
PODMAN_STORAGE=$(podman info --format json | jq -r '.store.graphRoot')

podman run -v "$CONFIG_ABS":/config.yaml:Z \
             -v "$PWD"/build:/tmp/auroraboot:Z \
             -v "$XDG_RUNTIME_DIR"/podman/podman.sock:/var/run/docker.sock \
             -v "$PODMAN_STORAGE":/var/lib/containers/storage:Z \
             --security-opt label=disable \
             --rm -ti quay.io/kairos/auroraboot \
             --set container_image=$IMAGE \
             --set "disable_http_server=true" \
             --set "disable_netboot=true" \
             --cloud-config /config.yaml \
             --set "state_dir=/tmp/auroraboot"

