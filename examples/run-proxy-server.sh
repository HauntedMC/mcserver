#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Run a Minecraft proxy container (Velocity/Bungee workflow).
#
# Defaults include Aikar's recommended JVM flags.
# Bedrock and Votifier publishing are optional and disabled by default.
###############################################################################

# ============================== CONFIG =======================================

# Container user/group IDs (must match image build args).
CONTAINER_UID=10001
CONTAINER_GID=10001

# Host path mounted to /data in the container.
DATA_DIR="./data"

# Docker network to join (must exist).
NETWORK="your-docker-network"

# Optional static container IP.
# Leave empty for dynamic assignment. A static IP is often useful for proxies.
CONTAINER_IP=""

# Container identity.
CONTAINER_NAME="proxy"
IMAGE="ghcr.io/hauntedmc/mcserver:latest"

# URL used to download proxy `server.jar` at startup.
JAR_URL="https://example.com/path/to/velocity.jar"

# Java runtime settings.
MEMORY="2G"
# Aikar recommended G1GC flags for Minecraft servers.
JAVA_ARGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
TIMEZONE="Europe/Amsterdam"

# Port publishing.
# Java is always published (TCP + UDP). Bedrock/Votifier are opt-in.
BIND_IP="0.0.0.0"
JAVA_PORT="25565"
ENABLE_BEDROCK="false"
ENABLE_VOTIFIER="false"
BEDROCK_PORT="19132"
VOTIFIER_PORT="8249"

# ======================== HOST PERMISSIONS ===================================

# Ensure DATA_DIR exists and is writable by the non-root container user.
install -d -m 2775 -o "${CONTAINER_UID}" -g "${CONTAINER_GID}" "${DATA_DIR}"
chown -R "${CONTAINER_UID}:${CONTAINER_GID}" "${DATA_DIR}" || true
find "${DATA_DIR}" -type d -exec chmod 2775 {} +
find "${DATA_DIR}" -type f -exec chmod g+w,o-rwx {} +
if command -v setfacl >/dev/null 2>&1; then
  setfacl -R -m g:${CONTAINER_GID}:rwx -m d:g:${CONTAINER_GID}:rwx "${DATA_DIR}" || true
fi

# ================================ RUN ========================================

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

is_true() {
  case "${1,,}" in
    true|yes|1|on) return 0 ;;
    *) return 1 ;;
  esac
}

port_args=(
  -p "${BIND_IP}:${JAVA_PORT}:${JAVA_PORT}/tcp"
  -p "${BIND_IP}:${JAVA_PORT}:${JAVA_PORT}/udp"
)

if is_true "${ENABLE_BEDROCK}"; then
  port_args+=(
    -p "${BIND_IP}:${BEDROCK_PORT}:${BEDROCK_PORT}/tcp"
    -p "${BIND_IP}:${BEDROCK_PORT}:${BEDROCK_PORT}/udp"
  )
fi

if is_true "${ENABLE_VOTIFIER}"; then
  port_args+=(-p "${BIND_IP}:${VOTIFIER_PORT}:${VOTIFIER_PORT}/tcp")
fi

ip_args=()
if [[ -n "${CONTAINER_IP}" ]]; then
  ip_args=(--ip "${CONTAINER_IP}")
fi

# docker run flags reference:
# - --network/--ip: joins the configured network; static IP is optional
# - --restart unless-stopped + -d: resilient background service behavior
# - port_args: Java is always published; Bedrock/Votifier only if enabled
# - -e TZ/JVM_MEMORY/JAVA_ARGS/JAR_URL: runtime configuration for the image
# - -v DATA_DIR:/data: persistent proxy files (configs, plugins, logs, jar)
# - --read-only + --tmpfs /tmp: immutable root filesystem with writable /tmp
# - --cap-drop ALL + no-new-privileges + --pids-limit: hardening
# - --ulimit/--stop-timeout/--log-*: operational safety and log rotation

docker run --name "${CONTAINER_NAME}" \
  --network "${NETWORK}" \
  "${ip_args[@]}" \
  --restart unless-stopped \
  -d \
  "${port_args[@]}" \
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
  --ulimit nofile=262144:262144 \
  --stop-timeout 90 \
  --log-driver json-file \
  --log-opt max-size=10m --log-opt max-file=5 \
  -it "${IMAGE}"
