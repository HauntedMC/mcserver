#!/bin/sh
set -eu

# shellcheck disable=SC1091
. /app/lib.sh

# Downloads /data/server.jar from JAR_URL.
# Behavior is controlled with:
# - JAR_DOWNLOAD_MODE: always | if-missing | if-url-changed
# - JAR_DOWNLOAD_TIMEOUT: curl max-time in seconds (default: 300)
# - JAR_SHA256: optional expected SHA-256 checksum

# Runtime state is always written under /data.
cd /data

# JAR_URL is required because the image intentionally does not embed server jars.
require_env JAR_URL "Set JAR_URL to a direct download URL for your server jar."

download_mode="${JAR_DOWNLOAD_MODE:-always}"
download_timeout="${JAR_DOWNLOAD_TIMEOUT:-300}"

case "$download_mode" in
  always|if-missing|if-url-changed) ;;
  *)
    die "Unsupported JAR_DOWNLOAD_MODE '$download_mode'. Valid values: always, if-missing, if-url-changed."
    ;;
esac

# Decide whether a new download is required for this startup.
should_download="true"
if [ "$download_mode" = "if-missing" ] && [ -s server.jar ]; then
  should_download="false"
elif [ "$download_mode" = "if-url-changed" ] && [ -s server.jar ] && [ -f .jar.url ]; then
  previous_url=$(cat .jar.url 2>/dev/null || true)
  if [ "$previous_url" = "$JAR_URL" ]; then
    should_download="false"
  fi
fi

if [ "$should_download" != "true" ]; then
  _log INFO "Skipping JAR download (mode=$download_mode)."
  exit 0
fi

# Ensure partially downloaded temp files are removed on exit/failure.
tmp_file=""
cleanup() {
  if [ -n "$tmp_file" ] && [ -f "$tmp_file" ]; then
    rm -f "$tmp_file"
  fi
}
trap cleanup EXIT INT TERM HUP

# Download to a temporary file and move into place atomically.
tmp_file=$(mktemp /data/server.jar.tmp.XXXXXX)

_log INFO "Downloading server JAR from configured URL."
if command_exists curl; then
  if ! curl -sS -fL --retry 5 --retry-delay 2 --retry-all-errors --connect-timeout 10 --max-time "$download_timeout" \
    -o "$tmp_file" "$JAR_URL"; then
    die "curl download failed for JAR_URL."
  fi
elif command_exists wget; then
  if ! wget -q -t 5 --waitretry=2 -O "$tmp_file" "$JAR_URL"; then
    die "wget download failed for JAR_URL."
  fi
else
  die "Neither curl nor wget is available in the image."
fi

# Reject empty downloads to avoid launching with a corrupt artifact.
if [ ! -s "$tmp_file" ]; then
  die "Downloaded file is empty."
fi

# Optional integrity gate for supply-chain hardening.
if [ -n "${JAR_SHA256:-}" ]; then
  _log INFO "Verifying downloaded JAR checksum."
  if command_exists sha256sum; then
    actual_checksum=$(sha256sum "$tmp_file" | awk '{print $1}')
  elif command_exists shasum; then
    actual_checksum=$(shasum -a 256 "$tmp_file" | awk '{print $1}')
  else
    die "JAR_SHA256 is set but no checksum tool is available (sha256sum/shasum)."
  fi

  if [ "$actual_checksum" != "$JAR_SHA256" ]; then
    die "Checksum mismatch for downloaded JAR."
  fi
  printf '%s\n' "$JAR_SHA256" > .jar.sha256
else
  rm -f .jar.sha256
fi

# Replace previous jar and persist metadata for mode decisions next startup.
mv -f "$tmp_file" server.jar
tmp_file=""
chmod g+rw server.jar || true
printf '%s\n' "$JAR_URL" > .jar.url

_log INFO "Server JAR downloaded."
