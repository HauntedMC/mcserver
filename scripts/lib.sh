#!/bin/sh

# Shared POSIX shell helpers used by runtime scripts.
# Keep this file strictly POSIX-sh compatible.

_ts() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# _log LEVEL MESSAGE...
# Prints timestamped logs in a stable format for container logs.
_log() {
  level="$1"
  shift || true
  msg="$*"
  case "$level" in
    INFO)  printf "%s [INFO]  %s\n" "$(_ts)" "$msg" ;;
    WARN)  printf "%s [WARN]  %s\n" "$(_ts)" "$msg" >&2 ;;
    ERROR) printf "%s [ERROR] %s\n" "$(_ts)" "$msg" >&2 ;;
    *)     printf "%s [LOG]   %s %s\n" "$(_ts)" "$level" "$msg" ;;
  esac
}

# die MESSAGE...
# Emits an error log and exits non-zero.
die() {
  _log ERROR "$*"
  exit 1
}

# command_exists NAME
# Returns success if command NAME is available in PATH.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# require_env NAME [HINT]
# Fails when NAME is missing or empty.
require_env() {
  name="$1"
  hint="${2:-}"
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    if [ -n "$hint" ]; then
      die "Missing required environment variable '$name'. $hint"
    fi
    die "Missing required environment variable '$name'."
  fi
}

# is_true VALUE
# Accepts common truthy strings used in env vars.
is_true() {
  case "${1:-}" in
    true|TRUE|True|yes|YES|Yes|1|on|ON|On) return 0 ;;
    *) return 1 ;;
  esac
}
