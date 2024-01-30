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

#FIX_QUERY_RANGE=$TOTAL_TIME_RANGE
FIX_M=480
# 控制m是4的整数倍

#hasHeader=false # default

echo 3 |sudo tee /proc/sys/vm/drop_cache
free -m
echo "Begin experiment!"


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
cp ../../iotdb-engine-example.properties iotdb-engine-USE.properties

# [write data]
echo "Writing data"
cp iotdb-engine-USE.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh /dev/null 2>&1 &
sleep 8s
# Usage: java -jar WriteDataUCR.jar device measurement timestamp_precision dataType valueEncoding iotdb_chunk_point_size filePath
java -jar $HOME_PATH/WriteDataUCR*.jar ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_TYPE} ${VALUE_ENCODING} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}.csv
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


# [query data]
echo "Querying data"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
mkdir vary_range

# attention: case sensitive
approachArray=("MinMax" "M4" "LTTB" "MinMaxLTTB" "ILTS" "MinMax_UDF" "M4_UDF" "LTTB_UDF");
# TODO MinMaxLTTB_UDF
for approach in ${approachArray[@]};
do
echo "[[[[[[[[[[[[[$approach]]]]]]]]]]]]]"

cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_range
mkdir $approach
cd $approach
cp $HOME_PATH/ProcessResult.* .

# attention: case sensitive enable_Tri
$HOME_PATH/tool.sh enable_Tri ${approach} $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties

#if [ $approach == "minmax_lsm" ]
#then
#  $HOME_PATH/tool.sh enable_tri ${approach} $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
#else
#  cp ../../iotdb-engine-enableCPV.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
#fi

i=1
# 控制m是4的整数倍
#for m in 100 # 200 400 # 600 1200 2000 3000 4000
for per in 1 5 10 20 40 60 80 100
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"

#  $HOME_PATH/tool.sh SAVE_QUERY_RESULT_PATH ${HOME_PATH}/data-${approach}-${m}.csv $HOME_PATH/query_experiment.sh

  # for query latency exp
  if [ $approach == "LTTB_UDF" ]
  then # rep=1 is enough for slow LTTB
    # Note the following command print info is appended into result_${i}.txt for query latency exp
    $HOME_PATH/tool.sh REP_ONCE true $HOME_PATH/query_experiment.sh
    find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;
    # device measurement timestamp_precision dataMinTime dataMaxTime range m approach save_query_result save_query_path
    $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_M} $approach >> result_${i}.txt
  else # default rep
    # Note the following command print info is appended into result_${i}.txt for query latency exp
    $HOME_PATH/tool.sh REP_ONCE false $HOME_PATH/query_experiment.sh
    find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;
    # device measurement timestamp_precision dataMinTime dataMaxTime range m approach save_query_result save_query_path
    $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_M} $approach >> result_${i}.txt
  fi

  java ProcessResult result_${i}.txt result_${i}.out ../sumResult_${approach}.csv
  let i+=1
done

done;


 approachArray=("MinMax" "M4" "LTTB" "MinMaxLTTB" "ILTS" "MinMax_UDF" "M4_UDF" "LTTB_UDF");
# 注意要改编号还有csv文件名！
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_range
(cut -f 2 -d "," sumResult_MinMax.csv) > tmp1.csv
(cut -f 2 -d "," sumResult_M4.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 2 -d "," sumResult_LTTB.csv| paste -d, tmp2.csv -) > tmp3.csv
(cut -f 2 -d "," sumResult_MinMaxLTTB.csv| paste -d, tmp3.csv -) > tmp4.csv
(cut -f 2 -d "," sumResult_ILTS.csv| paste -d, tmp4.csv -) > tmp5.csv
(cut -f 2 -d "," sumResult_MinMax_UDF.csv| paste -d, tmp5.csv -) > tmp6.csv
(cut -f 2 -d "," sumResult_M4_UDF.csv| paste -d, tmp6.csv -) > tmp7.csv
(cut -f 2 -d "," sumResult_LTTB_UDF.csv| paste -d, tmp7.csv -) > tmp8.csv
echo "MinMax(ns),M4(ns),LTTB(ns),MinMaxLTTB(ns),ILTS(ns),MinMax_UDF(ns),M4_UDF(ns),LTTB_UDF(ns)" > $HOME_PATH/res-${DATASET}.csv
sed '1d' tmp8.csv >> $HOME_PATH/res-${DATASET}.csv
rm tmp*.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/m/(totalRange/(pointNum/chunkSize))
# range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/m
sed -i -e 1's/^/range,estimated chunks per interval,/' $HOME_PATH/res-${DATASET}.csv
line=2
for per in 1 5 10 20 40 60 80 100 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  c=$((echo scale=0 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_M}*${per}/100) | bc )
  sed -i -e ${line}"s/^/${range},${c},/" $HOME_PATH/res-${DATASET}.csv
  let line+=1
done


echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m