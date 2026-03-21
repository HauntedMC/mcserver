#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Run a Minecraft proxy container (Velocity/Bungee workflow).
#
# Defaults include Aikar's recommended JVM flags.
# Bedrock and Votifier publishing are optional and disabled by default.
###############################################################################

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log() {
  local level="$1"
  shift || true
  local message="$*"
  case "$level" in
    INFO) printf "%s [INFO]  %s\n" "$(timestamp)" "$message" ;;
    WARN) printf "%s [WARN]  %s\n" "$(timestamp)" "$message" >&2 ;;
    ERROR) printf "%s [ERROR] %s\n" "$(timestamp)" "$message" >&2 ;;
    *) printf "%s [LOG]   %s %s\n" "$(timestamp)" "$level" "$message" ;;
  esac
}

fail() {
  log ERROR "$*"
  exit 1
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "Required command '$cmd' is not available in PATH."
  fi
}

ensure_docker_access() {
  if ! docker info >/dev/null 2>&1; then
    fail "Docker daemon is not reachable. Start Docker and retry."
  fi
}

ensure_network_exists() {
  local network="$1"
  if [[ -z "$network" || "$network" == "bridge" ]]; then
    return 0
  fi
  if ! docker network inspect "$network" >/dev/null 2>&1; then
    fail "Docker network '$network' does not exist. Create it first with: docker network create $network"
  fi
}

ensure_data_dir_permissions() {
  local data_dir="$1"
  local uid="$2"
  local gid="$3"

  install -d -m 2775 "$data_dir"

  if ! chown -R "${uid}:${gid}" "$data_dir" 2>/dev/null; then
    log WARN "Could not chown '$data_dir' to ${uid}:${gid}; continuing."
  fi
  if ! find "$data_dir" -type d -exec chmod 2775 {} + 2>/dev/null; then
    log WARN "Could not update directory permissions under '$data_dir'; continuing."
  fi
  if ! find "$data_dir" -type f -exec chmod g+w,o-rwx {} + 2>/dev/null; then
    log WARN "Could not update file permissions under '$data_dir'; continuing."
  fi

  if command -v setfacl >/dev/null 2>&1; then
    setfacl -R -m "g:${gid}:rwx" -m "d:g:${gid}:rwx" "$data_dir" || true
  fi
}

is_true() {
  case "${1,,}" in
    true|yes|1|on) return 0 ;;
    *) return 1 ;;
  esac
}

# ============================== CONFIG =======================================

# Container user/group IDs (must match image build args).
CONTAINER_UID=10001
CONTAINER_GID=10001

# Host path mounted to /data in the container.
DATA_DIR="./data"

# Docker network to join.
NETWORK="bridge"

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

# Optional integrity check for downloaded proxy jar.
JAR_SHA256=""

# Download behavior: always | if-missing | if-url-changed
JAR_DOWNLOAD_MODE="always"

# Port publishing.
# Java is always published (TCP + UDP). Bedrock/Votifier are opt-in.
BIND_IP="0.0.0.0"
JAVA_PORT="25565"
ENABLE_BEDROCK="false"
ENABLE_VOTIFIER="false"
BEDROCK_PORT="19132"
VOTIFIER_PORT="8249"

# ======================== HOST PERMISSIONS ===================================

require_command docker
ensure_docker_access
ensure_network_exists "${NETWORK}"
ensure_data_dir_permissions "${DATA_DIR}" "${CONTAINER_UID}" "${CONTAINER_GID}"

# ================================ RUN ========================================

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

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
  -e JAR_SHA256="${JAR_SHA256}" \
  -e JAR_DOWNLOAD_MODE="${JAR_DOWNLOAD_MODE}" \
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

log INFO "Container '${CONTAINER_NAME}' started."
log INFO "Attach with: docker attach ${CONTAINER_NAME}"
