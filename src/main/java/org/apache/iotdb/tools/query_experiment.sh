#!/bin/bash
HOME_PATH=/data/rl/v1

IOTDB_SBIN_HOME=$HOME_PATH/iotdb-server-0.12.4/sbin
QUERY_JAR_PATH=$HOME_PATH/QueryData-0.12.4.jar

echo 3 | sudo tee /proc/sys/vm/drop_caches
cd $IOTDB_SBIN_HOME
a=20
for((i=0;i<a;i++)) do
    ./start-server.sh /dev/null 2>&1 &
    sleep 5s
    java -jar $QUERY_JAR_PATH $1 $2 $3 $4 $5 $6 $7 $8
    ./stop-server.sh
    sleep 5s
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    sleep 3s
done
