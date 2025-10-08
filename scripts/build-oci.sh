#!/bin/bash
set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [--push]"
    echo ""
    echo "Environment Variables:"
    echo "  REPOSITORY:        Repository name (default: localai-zta)"
    echo "  ARTIFACT_VERSION:  Version tag for the final image (optional, defaults to latest LocalAI release)"
    echo "  LOCALAI_VERSION:   LocalAI version to use (optional, defaults to latest LocalAI release)"
    echo "  VARIANT:           Appliance variant - 'core' (systemd) or 'standard' (kubernetes) (default: core)"
    echo ""
    echo "Options:"
    echo "  --push:            Push the built image to the repository (default: false)"
    echo "  --help, -h:        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build core variant with latest LocalAI version"
    echo "  VARIANT=standard $0                   # Build standard (kubernetes) variant"
    echo "  REPOSITORY=my-repo $0                 # Build with custom repository"
    echo "  REPOSITORY=my-repo ARTIFACT_VERSION=v1.0.0 $0  # Build with custom repository and artifact version"
    echo "  REPOSITORY=my-repo ARTIFACT_VERSION=v1.0.0 LOCALAI_VERSION=v3.5.4 VARIANT=standard $0  # Build standard variant with custom versions"
    echo "  REPOSITORY=my-repo ARTIFACT_VERSION=v1.0.0 $0 --push  # Build and push"
}

# Parse command line arguments
PUSH=false
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
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Set defaults from environment variables
REPOSITORY=${REPOSITORY:-localai-zta}
ARTIFACT_VERSION=${ARTIFACT_VERSION:-}
LOCALAI_VERSION=${LOCALAI_VERSION:-}
VARIANT=${VARIANT:-core}

# Validate VARIANT
if [[ "$VARIANT" != "core" && "$VARIANT" != "standard" ]]; then
    echo "Error: VARIANT must be either 'core' or 'standard', got: $VARIANT" >&2
    exit 1
fi


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

# If no LocalAI version is provided, fetch the latest version
if [ -z "$LOCALAI_VERSION" ]; then
    LOCALAI_VERSION=$(get_latest_version)
    echo "Using latest LocalAI version: $LOCALAI_VERSION"
fi

# If no artifact version is provided, use the LocalAI version
if [ -z "$ARTIFACT_VERSION" ]; then
    ARTIFACT_VERSION="$LOCALAI_VERSION"
    echo "Using LocalAI version as artifact version: $ARTIFACT_VERSION"
else
    echo "Using provided artifact version: $ARTIFACT_VERSION"
fi

echo "Final build variables:"
echo "  REPOSITORY: $REPOSITORY"
echo "  ARTIFACT_VERSION: $ARTIFACT_VERSION"
echo "  LOCALAI_VERSION: $LOCALAI_VERSION"
echo "  VARIANT: $VARIANT"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building OCI image: $REPOSITORY:${ARTIFACT_VERSION}_${VARIANT} (variant: $VARIANT)"
echo "Building stage 1: LocalAI base image (LocalAI version: $LOCALAI_VERSION)..."
podman build --build-arg=LOCALAI_VERSION="$LOCALAI_VERSION" --build-arg=VARIANT="$VARIANT" --security-opt label=disable -t "$REPOSITORY:${ARTIFACT_VERSION}_${VARIANT}-stage1" "$PROJECT_ROOT/images/stage-1"

echo "Building stage 2: Final image with Kairos integration..."
podman build --build-arg=BASE_IMAGE="$REPOSITORY:${ARTIFACT_VERSION}_${VARIANT}-stage1" --build-arg=VERSION="$ARTIFACT_VERSION" --build-arg=VARIANT="$VARIANT" --security-opt label=disable -t "$REPOSITORY:${ARTIFACT_VERSION}_${VARIANT}" "$PROJECT_ROOT/images/stage-2"

if [ "$PUSH" = true ]; then
    echo "Pushing image to repository: $REPOSITORY:${ARTIFACT_VERSION}_${VARIANT}"
    podman push "$REPOSITORY":"${ARTIFACT_VERSION}_${VARIANT}"
    echo "Successfully pushed $REPOSITORY:${ARTIFACT_VERSION}_${VARIANT}"
else
    echo "Image built successfully. Use --push flag to push to repository."
fi