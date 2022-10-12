#!/bin/bash

# generate HOME_PATH workspace by running prepare.sh first
HOME_PATH=/data/rl/v4

# dataset basic info
DATASET=BallSpeed
DEVICE=root.game
MEASUREMENT=s6
DATA_TYPE=long
TIMESTAMP_PRECISION=ns
DATA_MIN_TIME=0
DATA_MAX_TIME=617426057626
TOTAL_POINT_NUMBER=1200000
let TOTAL_TIME_RANGE=${DATA_MAX_TIME}-${DATA_MIN_TIME} #TODO check what if not +1 what the difference

regular_time_interval=511996

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