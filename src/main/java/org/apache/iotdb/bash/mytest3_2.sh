#!/bin/bash

# generate HOME_PATH workspace by running prepare.sh first
HOME_PATH=/data/rl/v1

# dataset basic info
DATASET=KOB_2
DEVICE=root.kobelco.trans.03.1090001603.2401604
MEASUREMENT=KOB_0002_00_67
DATA_TYPE=long
TIMESTAMP_PRECISION=ms
DATA_MIN_TIME=1616805035000
DATA_MAX_TIME=1627380839000
TOTAL_POINT_NUMBER=1860287
let TOTAL_TIME_RANGE=${DATA_MAX_TIME}-${DATA_MIN_TIME} #TODO check what if not +1 what the difference

regular_time_interval=1000

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
# Vary overlap percentage: 0%,10%,30%,50%,70%,90%
############################
echo "prepare out-of-order source data"
cd $HOME_PATH/${DATASET}
cp ${DATASET}.csv ${DATASET}-O_0
# java OverlapGenerator iotdb_chunk_point_size dataType inPath outPath timeIdx valueIdx overlapPercentage overlapDepth
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_10 0 1 10 10
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_30 0 1 30 10
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_50 0 1 50 10
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_70 0 1 70 10
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_90 0 1 90 10

############################
# O_0_D_0_0
############################

OVERLAP_PERCENTAGE=0
DELETE_PERCENTAGE=0
DELETE_RANGE=0

cd $HOME_PATH/${DATASET}_testspace
mkdir O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}
cd O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}

# prepare IoTDB config properties
$HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh unseq_tsfile_size 1073741824 $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh seq_tsfile_size 1073741824 $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh compaction_strategy NO_COMPACTION $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh enable_unseq_compaction false $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh page_size_in_byte 1073741824 $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_address 0.0.0.0 $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_port 6667 $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh enable_CPV true $HOME_PATH/iotdb-engine-example.properties

# properties for using regularity-aware TS_2DIFF codec
$HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/enableRegularTrue/system $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/enableRegularTrue/data $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/enableRegularTrue/wal $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh enable_regularity_time_decode true $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh regular_time_interval ${regular_time_interval} $HOME_PATH/iotdb-engine-example.properties
cp $HOME_PATH/iotdb-engine-example.properties iotdb-engine-enableRegularTrue.properties

# properties for NOT using regularity-aware TS_2DIFF codec
$HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/enableRegularFalse/system $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/enableRegularFalse/data $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/enableRegularFalse/wal $HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh enable_regularity_time_decode false $HOME_PATH/iotdb-engine-example.properties
cp $HOME_PATH/iotdb-engine-example.properties iotdb-engine-enableRegularFalse.properties

# write data
echo "Writing O_0_D_0_0 using regularity-aware TS_2DIFF codec"
cp $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/iotdb-engine-enableRegularTrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh /dev/null 2>&1 &
sleep 5s
# Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_${OVERLAP_PERCENTAGE} ${DELETE_PERCENTAGE} ${DELETE_RANGE} 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches

# write data
echo "Writing O_0_D_0_0 NOT using regularity-aware TS_2DIFF codec"
cp $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/iotdb-engine-enableRegularFalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh /dev/null 2>&1 &
sleep 5s
# Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_${OVERLAP_PERCENTAGE} ${DELETE_PERCENTAGE} ${DELETE_RANGE} 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


# query data
echo "Querying O_0_D_0_0 using regularity-aware TS_2DIFF codec"
cd $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}

echo "enableRegularTrue query testing..."
mkdir enableRegularTrue
cd enableRegularTrue

echo "M4-UDF"
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/iotdb-engine-enableRegularTrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w mac >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMAC.csv
  let i+=1
done

echo "M4-LSM"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/iotdb-engine-enableRegularTrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w cpv >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# query data
cd $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}
echo "enableRegularFalse query testing..."
mkdir enableRegularFalse
cd enableRegularFalse

echo "M4-UDF"
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/iotdb-engine-enableRegularFalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w mac >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMAC.csv
  let i+=1
done

echo "M4-LSM"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp $HOME_PATH/${DATASET}_testspace/O_${OVERLAP_PERCENTAGE}_D_${DELETE_PERCENTAGE}_${DELETE_RANGE}/iotdb-engine-enableRegularFalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w cpv >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

echo "finish!"