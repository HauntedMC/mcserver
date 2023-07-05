cd data

curl -L -o server.jar ${JAR_URL}

exec java ${JVM_MEMORY_OPTIONS} ${JAVA_ARGS} -jar server.jar --nogui
