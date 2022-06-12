#!/bin/bash
HOME_PATH=/data/rl/v1
JAR_RELATIVE_PATH=BallSpeed_testspace/QueryBallSpeed-0.12.4.jar

IOTDB_SBIN_HOME=$HOME_PATH/iotdb-server-0.12.4/sbin
QUERY_JAR_PATH=$HOME_PATH/$JAR_RELATIVE_PATH

echo 3 | sudo tee /proc/sys/vm/drop_caches
cd $IOTDB_SBIN_HOME
a=5
for((i=0;i<a;i++)) do
    ./start-server.sh &
    sleep 3s
    java -jar $QUERY_JAR_PATH $1 $2 $3
    ./stop-server.sh
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    sleep 3s
done
