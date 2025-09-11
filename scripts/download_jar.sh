#!/bin/sh
set -eu

cd /data

# --- logging (POSIX-sh safe) ----------------------------------------------
_ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
_log() {
  level="$1"; shift || true
  msg="$*"
  case "$level" in
    INFO)  printf "%s [INFO]  %s\n"  "$(_ts)" "$msg";;
    WARN)  printf "%s [WARN]  %s\n"  "$(_ts)" "$msg" >&2;;
    ERROR) printf "%s [ERROR] %s\n"  "$(_ts)" "$msg" >&2;;
    *)     printf "%s [LOG]   %s %s\n" "$(_ts)" "$level" "$msg";;
  esac
}

_log INFO "Downloading Server Jar.."
tmp="server.jar.tmp.$$"

if command -v curl >/dev/null 2>&1; then
  # same behavior, quieter output
  if ! curl -sS -fL --retry 5 --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$tmp" "${JAR_URL}"; then
    _log ERROR "curl download failed."
    exit 1
  fi
elif command -v wget >/dev/null 2>&1; then
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
