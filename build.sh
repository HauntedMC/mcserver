#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./build.sh [options]

Options:
  --tag <name>          Image tag to produce (default: mcserver:nonroot)
  --uid <id>            Container user ID build arg (default: 10001)
  --gid <id>            Container group ID build arg (default: 10001)
  --no-cache            Disable Docker build cache (default: enabled)
  --no-pull             Do not pull newer base image before build
  -h, --help            Show this help text
EOF
}

IMAGE_TAG="mcserver:nonroot"
CONTAINER_UID="10001"
CONTAINER_GID="10001"
PULL_BASE="true"
USE_CACHE="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --tag" >&2
        exit 1
      fi
      IMAGE_TAG="$2"
      shift 2
      ;;
    --uid)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --uid" >&2
        exit 1
      fi
      CONTAINER_UID="$2"
      shift 2
      ;;
    --gid)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --gid" >&2
        exit 1
      fi
      CONTAINER_GID="$2"
      shift 2
      ;;
    --no-cache)
      USE_CACHE="false"
      shift
      ;;
    --no-pull)
      PULL_BASE="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

docker_args=(
  --build-arg "UID=${CONTAINER_UID}"
  --build-arg "GID=${CONTAINER_GID}"
  -t "${IMAGE_TAG}"
)

if [[ "$PULL_BASE" == "true" ]]; then
  docker_args+=(--pull)
fi
if [[ "$USE_CACHE" == "false" ]]; then
  docker_args+=(--no-cache)
fi

docker build "${docker_args[@]}" .
