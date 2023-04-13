#!/bin/bash

# generate HOME_PATH workspace by running prepare.sh first
HOME_PATH=/data/rl/v4

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

# iotdb config info
IOTDB_CHUNK_POINT_SIZE=100

# exp controlled parameter design
FIX_W=1000
FIX_QUERY_RANGE=$TOTAL_TIME_RANGE
FIX_OVERLAP_PERCENTAGE=10
FIX_DELETE_PERCENTAGE=49
FIX_DELETE_RANGE=10

echo 3 |sudo tee /proc/sys/vm/drop_cache
free -m
echo "Begin experiment!"

############################
# prepare out-of-order source data.
# Vary overlap percentage: 0%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%
############################
echo "prepare out-of-order source data"
cd $HOME_PATH/${DATASET}
cp ${DATASET}.csv ${DATASET}-O_0

overlap_percentage in 0
do
  workspace="O_${overlap_percentage}_D_0_0"
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
  $HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  # properties for cpv true and disable chunk index
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh use_ChunkIndex false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-disableChunkIndex.properties
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
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_${overlap_percentage} 0 0 0 1 ${VALUE_ENCODING}
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # [query data]
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix

  echo "without chunk index"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-disableChunkIndex.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  echo "with chunk index"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableChunkIndex.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  # unify results
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  cp $HOME_PATH/SumResultUnify.* .
  java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv
done


echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m