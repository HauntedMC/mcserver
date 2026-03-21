#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Run a Minecraft Java server container.
#
# Defaults include Aikar's recommended JVM flags.
# Update the CONFIG section, then execute this script.
###############################################################################

# ============================== CONFIG =======================================

# Container user/group IDs (must match image build args).
CONTAINER_UID=10001
CONTAINER_GID=10001

# Host path mounted to /data in the container.
DATA_DIR="./data"

# Docker network to join (must exist).
NETWORK="your-docker-network"

# Container identity.
CONTAINER_NAME="minecraft-server"
IMAGE="ghcr.io/hauntedmc/mcserver:latest"

# URL used to download `server.jar` at startup.
JAR_URL="https://example.com/path/to/server.jar"

# Java runtime settings.
MEMORY="8G"
# Aikar recommended G1GC flags for Minecraft servers.
JAVA_ARGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
TIMEZONE="Europe/Amsterdam"

# ======================== HOST PERMISSIONS ===================================

# Ensure DATA_DIR exists and is writable by the non-root container user.
install -d -m 2775 -o "${CONTAINER_UID}" -g "${CONTAINER_GID}" "${DATA_DIR}"
chown -R "${CONTAINER_UID}:${CONTAINER_GID}" "${DATA_DIR}"
find "${DATA_DIR}" -type d -exec chmod 2775 {} +
find "${DATA_DIR}" -type f -exec chmod g+w,o-rwx {} +
if command -v setfacl >/dev/null 2>&1; then
  setfacl -R -m g:${CONTAINER_GID}:rwx -m d:g:${CONTAINER_GID}:rwx "${DATA_DIR}" || true
fi

# ================================ RUN ========================================

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# docker run flags reference:
# - --network: joins a pre-created docker network
# - --restart unless-stopped: survives daemon/host restarts
# - -d -it: detached mode with TTY so `docker attach` remains convenient
# - -e TZ/JVM_MEMORY/JAVA_ARGS/JAR_URL: runtime configuration for the image
# - -v DATA_DIR:/data: persistent server files (world, configs, logs, jar)
# - --read-only + --tmpfs /tmp: immutable root filesystem with writable /tmp
# - --cap-drop ALL + --security-opt no-new-privileges + --pids-limit: hardening

docker run --name "${CONTAINER_NAME}" \
  --network "${NETWORK}" \
  --restart unless-stopped \
  -d \
  -e TZ="${TIMEZONE}" \
  -e JVM_MEMORY="${MEMORY}" \
  -e JAVA_ARGS="${JAVA_ARGS}" \
  -e JAR_URL="${JAR_URL}" \
  -v "${DATA_DIR}:/data" \
  --read-only \
  --tmpfs /tmp:rw,exec,size=128m \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --pids-limit 1024 \
  -it "${IMAGE}"
