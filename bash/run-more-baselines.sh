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
FIX_W=1000
FIX_QUERY_RANGE=$TOTAL_TIME_RANGE
FIX_OVERLAP_PERCENTAGE=10
FIX_DELETE_PERCENTAGE=49
FIX_DELETE_RANGE=10

hasHeader=false # default

echo 3 |sudo tee /proc/sys/vm/drop_cache
free -m
echo "Begin experiment!"

############################
# prepare out-of-order source data.
############################
echo "prepare out-of-order source data"
cd $HOME_PATH/${DATASET}
cp ${DATASET}.csv ${DATASET}-O_0
# java OverlapGenerator iotdb_chunk_point_size dataType inPath outPath timeIdx valueIdx overlapPercentage overlapDepth
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_10 0 1 10 10 ${hasHeader}

############################
# O_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_D_0_0
cd O_10_D_0_0

# prepare IoTDB config properties
$HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_D_0_0/system ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_D_0_0/data ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_D_0_0/wal ../../iotdb-engine-example.properties
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
$HOME_PATH/tool.sh error_Param 50 ../../iotdb-engine-example.properties

# properties for cpv
$HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
# properties for moc
$HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# [write data]
echo "Writing O_10_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh /dev/null 2>&1 &
sleep 8s
# Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 0 0 0 1 ${VALUE_ENCODING} ${hasHeader}
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


# [query data]
echo "Querying O_10_D_0_0 with varied w"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
mkdir vary_w

approachArray=("mac" "cpv" "minmax" "lttb");
# mac/moc/cpv/minmax/lttb/minmax_lsm
for approach in ${approachArray[@]};
do
echo $approach
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_w
mkdir $approach
cd $approach
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
# for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
for w in 1 2 50
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w $approach >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResult_${approach}.csv
  let i+=1
done

done;

cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_w
(cut -f 2 -d "," sumResult_mac.csv) > tmp1.csv
(cut -f 2 -d "," sumResult_cpv.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 2 -d "," sumResult_minmax.csv| paste -d, tmp2.csv -) > tmp3.csv
(cut -f 2 -d "," sumResult_lttb.csv| paste -d, tmp3.csv -) > tmp4.csv
echo "M4(ns),M4-LSM(ns),MINMAX(ns),LTTB(ns)" > $HOME_PATH/res.csv
sed '1d' tmp4.csv >> $HOME_PATH/res.csv
rm tmp1.csv
rm tmp2.csv
rm tmp3.csv
rm tmp4.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/w,estimated chunks per interval,/' $HOME_PATH/res.csv
line=2
#for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
for w in 1 2 50
do
  #let c=${pointNum}/${chunkSize}/$w # note bash only does the integer division
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/$w) | bc )
  sed -i -e ${line}"s/^/${w},${c},/" $HOME_PATH/res.csv
  let line+=1
done

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m