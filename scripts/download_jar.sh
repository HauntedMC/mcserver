#!/bin/sh
set -eu
cd /data

echo "Downloading Server Jar.."
tmp="server.jar.tmp.$$"

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 5 --retry-delay 2 --connect-timeout 10 --max-time 300 \
       -o "$tmp" "${JAR_URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$tmp" "${JAR_URL}"
else
  echo "ERROR: neither curl nor wget is available in the image." >&2
  exit 1
fi

mv -f "$tmp" server.jar
chmod g+rw server.jar || true
printf '%s' "${JAR_URL}" > .jar.url
