#!/bin/bash
set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [repository] [version] [--push]"
    echo "  repository: Repository name (default: localai-zta)"
    echo "  version:    Version tag for the image (optional, defaults to latest LocalAI release)"
    echo "  --push:     Push the built image to the repository (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Build with latest LocalAI version"
    echo "  $0 my-repo                   # Build with custom repository, latest version"
    echo "  $0 my-repo v1.40.0           # Build with custom repository and specific version"
    echo "  $0 my-repo v1.40.0 --push    # Build and push to custom repository"
}

PUSH=false
REPOSITORY=""
VERSION=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$REPOSITORY" ]; then
                REPOSITORY=$1
            elif [ -z "$VERSION" ]; then
                VERSION=$1
            fi
            shift
            ;;
    esac
done

# Set defaults
REPOSITORY=${REPOSITORY:-localai-zta}


# Function to get the latest LocalAI release version
get_latest_version() {
    echo "Fetching latest LocalAI release version..." >&2
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/mudler/LocalAI/releases/latest | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$')
    
    if [ -z "$latest_version" ]; then
        echo "Error: Failed to fetch latest version from GitHub API" >&2
        exit 1
    fi
    
    echo "Latest LocalAI version: $latest_version" >&2
    echo "$latest_version"
}

# If no version is provided, fetch the latest version
if [ -z "$VERSION" ]; then
    VERSION=$(get_latest_version)
    echo "Using latest version: $VERSION"
fi

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building OCI image: $REPOSITORY:$VERSION"
podman build --build-arg=VERSION="$VERSION" --security-opt label=disable -t "$REPOSITORY":"$VERSION" "$PROJECT_ROOT"

if [ "$PUSH" = true ]; then
    echo "Pushing image to repository: $REPOSITORY:$VERSION"
    podman push "$REPOSITORY":"$VERSION"
    echo "Successfully pushed $REPOSITORY:$VERSION"
else
    echo "Image built successfully. Use --push flag to push to repository."
fi