#!/bin/bash

# generate HOME_PATH workspace by running prepare.sh first
HOME_PATH=/data/v4

# dataset basic info
DATASET=BallSpeed # BallSpeed KOB MF03 RcvTime
DEVICE="root.game"
MEASUREMENT="s6"
DATA_TYPE=long # long or double
TIMESTAMP_PRECISION=ns
DATA_MIN_TIME=0  # in the corresponding timestamp precision
DATA_MAX_TIME=617426057626  # in the corresponding timestamp precision
TOTAL_POINT_NUMBER=1200000
let TOTAL_TIME_RANGE=${DATA_MAX_TIME}-${DATA_MIN_TIME} # check what if not +1 what the difference
VALUE_ENCODING=PLAIN
TIME_ENCODING=PLAIN
COMPRESSOR=UNCOMPRESSED

# iotdb config info
IOTDB_CHUNK_POINT_SIZE=100

# exp controlled parameter design
FIX_W=100
FIX_QUERY_RANGE=$TOTAL_TIME_RANGE
FIX_OVERLAP_PERCENTAGE=10
FIX_DELETE_PERCENTAGE=49
FIX_DELETE_RANGE=10

hasHeader=false # default


echo 3 |sudo tee /proc/sys/vm/drop_cache
free -m
echo "Begin experiment!"

perlist="100"
#perlist="20"

#echo "prepare out-of-order source data"
#cd $HOME_PATH/${DATASET}
#cp ${DATASET}.csv ${DATASET}-O_0
# java OverlapGenerator iotdb_chunk_point_size dataType inPath outPath timeIdx valueIdx overlapPercentage overlapDepth
#java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_90 0 1 90 50 ${hasHeader}
#java OverlapGenerator2 ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_90 0 1 ${TOTAL_POINT_NUMBER} 10000 1878 true

for per in $perlist
do
  MAX_POINTS_WRITE=$((echo scale=0 ; echo ${per}*${TOTAL_POINT_NUMBER}/100) | bc )
  echo "per=${per}% of ${TOTAL_POINT_NUMBER}, points=${MAX_POINTS_WRITE}"

  cd $HOME_PATH/${DATASET}_testspace
  mkdir O_10_D_0_0
  cd O_10_D_0_0

  # prepare IoTDB config properties
  $HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace_noMetadata_${per}/${DATASET}_O_10_D_0_0/system ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace_noMetadata_${per}/${DATASET}_O_10_D_0_0/data ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace_noMetadata_${per}/${DATASET}_O_10_D_0_0/wal ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh group_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties

  $HOME_PATH/tool.sh write_m4_lsm false ../../iotdb-engine-example.properties # note this!

  # note
  # enlarge memory allocation for write when writing
  $HOME_PATH/tool.sh write_read_schema_free_memory_proportion 6:1:1:2 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh MAX_HEAP_SIZE \"12G\" $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-env.sh

  cp ../../iotdb-engine-example.properties iotdb-engine-noMetadata.properties

  # [write data]
  echo "Writing data $DATASET (without precomputation)"
  cp iotdb-engine-noMetadata.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 8s
  start_time=$(date +%s%N)
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}.csv 0 0 0 1 ${VALUE_ENCODING} ${hasHeader} ${MAX_POINTS_WRITE}
  end_time=$(date +%s%N)
  duration_ns=$((end_time - start_time))
  echo "write latency of $DATASET (without precomputation) for $per is: $duration_ns ns"
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  ######################################################################

  # prepare IoTDB config properties
  $HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace_Metadata_${per}/${DATASET}_O_10_D_0_0/system ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace_Metadata_${per}/${DATASET}_O_10_D_0_0/data ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace_Metadata_${per}/${DATASET}_O_10_D_0_0/wal ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh group_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh error_Param 0.5 ../../iotdb-engine-example.properties

  $HOME_PATH/tool.sh write_m4_lsm true ../../iotdb-engine-example.properties # note this!

  # note
  # enlarge memory allocation for write when writing
  $HOME_PATH/tool.sh write_read_schema_free_memory_proportion 6:1:1:2 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh MAX_HEAP_SIZE \"12G\" $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-env.sh

  cp ../../iotdb-engine-example.properties iotdb-engine-Metadata.properties

  # [write data]
  echo "Writing data $DATASET (with precomputation)"
  cp iotdb-engine-Metadata.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 8s
  start_time=$(date +%s%N)
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}.csv 0 0 0 1 ${VALUE_ENCODING} ${hasHeader} ${MAX_POINTS_WRITE}
  end_time=$(date +%s%N)
  duration_ns=$((end_time - start_time))
  echo "write latency of $DATASET (with precomputation) for $per is: $duration_ns ns"
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

done

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m