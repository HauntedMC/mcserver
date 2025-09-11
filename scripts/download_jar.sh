#!/bin/sh
set -eu

cd /data

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

_log INFO "Downloading Server Jar.."
tmp="server.jar.tmp.$$"

if command -v curl >/dev/null 2>&1; then
  # same options as before, just quieter (-sS)
  if ! curl -sS -fL --retry 5 --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$tmp" "${JAR_URL}"; then
    _log ERROR "curl download failed."
    exit 1
  fi
elif command -v wget >/dev/null 2>&1; then
  # same options as before, just quieter (-q)
  if ! wget -q -O "$tmp" "${JAR_URL}"; then
    _log ERROR "wget download failed."
    exit 1
  fi
else
  _log ERROR "neither curl nor wget is available in the image."
  exit 1
fi

mv -f "$tmp" server.jar
chmod g+rw server.jar || true
printf '%s' "${JAR_URL}" > .jar.url

_log INFO "Server Jar downloaded."
