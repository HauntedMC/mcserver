cd data

bash ../download_jar.sh

echo "Starting Server.."
exec java -Xms${JVM_MEMORY} -Xmx${JVM_MEMORY} ${JAVA_ARGS} -jar server.jar --nogui
