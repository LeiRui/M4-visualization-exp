#!/bin/bash
HOME_PATH=/data/rl/v1

IOTDB_SBIN_HOME=$HOME_PATH/iotdb-server-0.12.4/sbin
QUERY_JAR_PATH=$HOME_PATH/QueryData-0.12.4.jar

echo 3 | sudo tee /proc/sys/vm/drop_caches
cd $IOTDB_SBIN_HOME

a=1
echo "rep=$a"

w=100

echo "n_ts=$7"

for((i=0;i<a;i++)) do
    echo $i
    ./start-server.sh /dev/null 2>&1 &
    sleep 12s

    for i in {1..$7} # query $7 number of time series simultaneously
    do
      java -jar $QUERY_JAR_PATH "$1$7" $2 $3 $4 $5 $6 $w $8 false NONE
    done;

    ./stop-server.sh
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    sleep 3s
done
