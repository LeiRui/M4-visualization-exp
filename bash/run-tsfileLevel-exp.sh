#!/bin/bash

# generate HOME_PATH workspace by running prepare.sh first
HOME_PATH=/data1/reply/v4

# dataset basic info
DATASET=BallSpeed # BallSpeed KOB MF03 RcvTime
DEVICE="root.game"
MEASUREMENT="s6"
DATA_TYPE=long # long or double
TIMESTAMP_PRECISION=ns
DATA_MIN_TIME=0  # in the corresponding timestamp precision
DATA_MAX_TIME=617426057626  # in the corresponding timestamp precision
TOTAL_POINT_NUMBER=1200000
let TOTAL_TIME_RANGE=${DATA_MAX_TIME}-${DATA_MIN_TIME} #TODO check what if not +1 what the difference
VALUE_ENCODING=PLAIN
TIME_ENCODING=PLAIN
COMPRESSOR=UNCOMPRESSED
use_Mad=false

# iotdb config info
IOTDB_CHUNK_POINT_SIZE=1000

# exp controlled parameter design
FIX_W=1000
FIX_QUERY_RANGE=$TOTAL_TIME_RANGE

echo 3 |sudo tee /proc/sys/vm/drop_cache
free -m
echo "Begin experiment!"

############################
# prepare data.
############################
echo "prepare out-of-order source data"
cd $HOME_PATH/${DATASET}
cp ${DATASET}.csv ${DATASET}-O_0

for NumberOfChunksInTsFile in 1 2 3 5 10 15 20 25 30 40 50 70 100 150 200 250
do
  workspace="O_0_D_0_0_${NumberOfChunksInTsFile}"
  cd $HOME_PATH/${DATASET}_testspace
  mkdir ${workspace}
  cd ${workspace}

  # prepare IoTDB config properties
  $HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/system ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_${workspace}/data ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/wal ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh avg_series_point_number_threshold 10000000 ../../iotdb-engine-example.properties # note here
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh use_Mad ${use_Mad} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_buffer_size 1073741824 ../../iotdb-engine-example.properties
  # properties for cpv true and enable chunk index
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh use_ChunkIndex true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableChunkIndex.properties

  # [write data]
  echo "Writing ${workspace}"
  cp iotdb-engine-enableChunkIndex.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 8s
  java -jar $HOME_PATH/WriteDataVaryChunkSize*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_0 0 1 ${VALUE_ENCODING} ${FIX_W} ${NumberOfChunksInTsFile}
  sleep 35s
  ./stop-server.sh
  sleep 10s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

#  cd $HOME_PATH/iotdb-server-0.12.4/sbin
#  ./start-server.sh /dev/null 2>&1 &
#  sleep 30s
#  ./stop-server.sh
#  sleep 20s
#  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # [query data]
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix

  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableChunkIndex.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # # unify results
  # cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  # cp $HOME_PATH/SumResultUnify.* .
  # java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv
done

echo "numberChunksInTsFile,queryTime(ms)" >> $HOME_PATH/${DATASET}_testspace/allResult.csv
for NumberOfChunksInTsFile in 1 2 3 5 10 15 20 25 30 40 50 70 100 150 200 250
do
  workspace="O_0_D_0_0_${NumberOfChunksInTsFile}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  queryTime=$(cat sumResultCPV.csv| cut -f 7 -d "," | sed -n 2p)
  echo ${NumberOfChunksInTsFile} "," ${queryTime}>> $HOME_PATH/${DATASET}_testspace/allResult.csv
done


echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m