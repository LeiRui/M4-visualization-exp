#!/bin/bash
HOME_PATH=/data/rl/v1

IOTDB_SBIN_HOME=$HOME_PATH/iotdb-server-0.12.4/sbin
QUERY_JAR_PATH=$HOME_PATH/QueryDataMultiSeries-jar-with-dependencies.jar

echo 3 | sudo tee /proc/sys/vm/drop_caches >>/dev/null
cd $IOTDB_SBIN_HOME

a=1
#echo "rep=$a"

w=100

#echo "n_ts=$7"

for((i=0;i<a;i++)) do
#    echo $i
    ./start-server.sh >>/dev/null 2>&1 &
    sleep 12s

    ts=$(date +%s%N) ;
    for ((deviceID=1; deviceID<=$7; deviceID++)); # query $7 number of time series simultaneously
    do
      java -jar $QUERY_JAR_PATH "$1${deviceID}" $2 $3 $4 $5 $6 $w $8 false NONE >>/dev/null 2>&1 &
      pids[${deviceID}]=$!
    done;
    for pid in ${pids[*]}; do
        wait $pid
    done
    # tt=$((($(date +%s%N) - $ts)/1000000)) ; echo "Time taken: $tt milliseconds"
    tt=$((($(date +%s%N) - $ts))) ; echo "$tt" # ns

    ./stop-server.sh >>/dev/null 2>&1
    echo 3 | sudo tee /proc/sys/vm/drop_caches >>/dev/null
    sleep 3s
done
