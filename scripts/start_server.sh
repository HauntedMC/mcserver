#!/bin/sh
set -eu

# shellcheck disable=SC1091
. /app/lib.sh

# Entrypoint script for the runtime container.
# Required env:
# - JVM_MEMORY
# - JAR_URL (validated in download_jar.sh)
#
# Optional env:
# - JAVA_ARGS
# - UMASK
# - EULA
# - JAR_DOWNLOAD_MODE
# - JAR_DOWNLOAD_TIMEOUT
# - JAR_SHA256

# Apply caller-defined umask before touching any files.
umask "${UMASK:-0002}"

# Always operate from /data
cd /data

require_env JVM_MEMORY "Set JVM_MEMORY like 2G, 4G, or 8192M."

# Write EULA marker when requested, so operators can automate acceptance.
if is_true "${EULA:-false}"; then
  printf 'eula=true\n' > eula.txt
  chmod g+rw eula.txt || true
  _log INFO "Wrote /data/eula.txt because EULA=true."
fi

# Let the helper decide if (and what) to download/replace
_log INFO "Invoking /app/download_jar.sh…"
/app/download_jar.sh

# Fail fast instead of passing a bad/missing jar to Java.
if [ ! -s server.jar ]; then
  die "server.jar is missing or empty after download."
fi

_log INFO "Starting server."
# shellcheck disable=SC2086
# JAVA_ARGS is intentionally word-split by shell to support multiple flags.
exec java -Xms"${JVM_MEMORY}" -Xmx"${JVM_MEMORY}" ${JAVA_ARGS:-} -jar server.jar --nogui
