cd data

bash ../download_jar.sh

echo "Starting Server.."
exec java ${JVM_MEMORY_OPTIONS} ${JAVA_ARGS} -jar server.jar --nogui
