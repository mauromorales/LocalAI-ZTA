#!/bin/bash
set -e

VERSION=$1
REPOSITORY=${2:-localai-zta}

if [ -z "$VERSION" ]; then
    echo "Error: VERSION argument is required"
    echo "Usage: $0 <version> [repository]"
    echo "  version:    Version tag for the image (required)"
    echo "  repository: Repository name (default: localai-zta)"
    exit 1
fi

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

podman build --build-arg=VERSION="$VERSION" --security-opt label=disable -t "$REPOSITORY":"$VERSION" "$PROJECT_ROOT"