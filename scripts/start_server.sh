#!/bin/sh
set -eu
umask "${UMASK:-0002}"

# Always operate from /data
cd /data

# Let the helper decide if (and what) to download/replace
/app/download_jar.sh

echo "Starting Server.."
exec java -Xms"${JVM_MEMORY}" -Xmx"${JVM_MEMORY}" ${JAVA_ARGS:-} -jar server.jar --nogui
