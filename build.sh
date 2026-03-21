#!/usr/bin/env bash
set -euo pipefail

docker build \
  --pull \
  --no-cache \
  --build-arg UID=10001 \
  --build-arg GID=10001 \
  -t mcserver:nonroot \
  .
