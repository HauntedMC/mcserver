#!/bin/sh
set -eu

umask "${UMASK:-0002}"

# --- logging (added) -------------------------------------------------------
_ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
_log() {
  case "$1" in
    INFO)  printf "%s [INFO]  %s\n"  "$(_ts)" "${*:2}";;
    WARN)  printf "%s [WARN]  %s\n"  "$(_ts)" "${*:2}" >&2;;
    ERROR) printf "%s [ERROR] %s\n"  "$(_ts)" "${*:2}" >&2;;
    *)     printf "%s [LOG]   %s\n"  "$(_ts)" "${*}";;
  esac
}

# Always operate from /data
cd /data

# Let the helper decide if (and what) to download/replace
_log INFO "Invoking /app/download_jar.sh…"
/app/download_jar.sh

_log INFO "Starting Server.."
exec java -Xms"${JVM_MEMORY}" -Xmx"${JVM_MEMORY}" ${JAVA_ARGS:-} -jar server.jar --nogui
