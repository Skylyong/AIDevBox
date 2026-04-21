#!/bin/bash
# Commit a running container and push it to the private registry.
#
# Defaults match the current AIDevBox container/image:
#   ./publish-container-last.sh
#
# Optional overrides:
#   ./publish-container-last.sh <container> <image> <tag>
#   CONTAINER_ID=a79777bf8d9a IMAGE_NAME=docker-server.tcm403.site/aidevbox IMAGE_TAG=last ./publish-container-last.sh

set -euo pipefail

DEFAULT_CONTAINER="${CONTAINER_ID:-a79777bf8d9a}"
DEFAULT_IMAGE_NAME="${IMAGE_NAME:-docker-server.tcm403.site/aidevbox}"
DEFAULT_IMAGE_TAG="${IMAGE_TAG:-last}"

usage() {
    cat <<EOF
Usage:
  $0 [container] [image] [tag]

Defaults:
  container: ${DEFAULT_CONTAINER}
  image:     ${DEFAULT_IMAGE_NAME}
  tag:       ${DEFAULT_IMAGE_TAG}

Examples:
  $0
  $0 a79777bf8d9a docker-server.tcm403.site/aidevbox last
  CONTAINER_ID=a79777bf8d9a IMAGE_NAME=docker-server.tcm403.site/aidevbox IMAGE_TAG=last $0
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

CONTAINER="${1:-$DEFAULT_CONTAINER}"
IMAGE_NAME="${2:-$DEFAULT_IMAGE_NAME}"
IMAGE_TAG="${3:-$DEFAULT_IMAGE_TAG}"
TARGET_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker command not found." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: cannot connect to Docker daemon." >&2
    exit 1
fi

STATUS="$(docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null || true)"
if [ -z "$STATUS" ]; then
    echo "Error: container not found: ${CONTAINER}" >&2
    exit 1
fi

if [ "$STATUS" != "running" ]; then
    echo "Error: container ${CONTAINER} is ${STATUS}, expected running." >&2
    exit 1
fi

SOURCE_IMAGE="$(docker inspect "$CONTAINER" --format '{{.Config.Image}}')"

echo "Container: ${CONTAINER}"
echo "Status:    ${STATUS}"
echo "Source:    ${SOURCE_IMAGE}"
echo "Target:    ${TARGET_IMAGE}"
echo

echo "Committing container to image..."
IMAGE_ID="$(docker commit "$CONTAINER" "$TARGET_IMAGE")"
echo "Committed: ${IMAGE_ID}"
echo

echo "Pushing image to registry..."
docker push "$TARGET_IMAGE"
echo

echo "Done: ${TARGET_IMAGE}"
