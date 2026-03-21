#!/usr/bin/env bash
set -euo pipefail

# ---------- config ----------
CONTAINER_UID=10001
CONTAINER_GID=10001
DATA_DIR="./data"
NETWORK="your-docker-network"

CONTAINER_NAME="minecraft-server"
JAVA_ARGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
MEMORY="8G"
IMAGE="ghcr.io/hauntedmc/mcserver:latest"
JAR_URL="https://example.com/path/to/server.jar"
TIMEZONE="Europe/Amsterdam"

# ---------- ensure perms on host ----------
install -d -m 2775 -o "${CONTAINER_UID}" -g "${CONTAINER_GID}" "${DATA_DIR}"

chown -R "${CONTAINER_UID}:${CONTAINER_GID}" "${DATA_DIR}"

find "${DATA_DIR}" -type d -exec chmod 2775 {} +
find "${DATA_DIR}" -type f -exec chmod g+w,o-rwx {} +

if command -v setfacl >/dev/null 2>&1; then
  setfacl -R -m g:${CONTAINER_GID}:rwx -m d:g:${CONTAINER_GID}:rwx "${DATA_DIR}" || true
fi

# ---------- run container ----------
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

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
