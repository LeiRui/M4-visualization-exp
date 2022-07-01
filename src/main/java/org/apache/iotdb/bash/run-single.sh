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

# iotdb config info
IOTDB_CHUNK_POINT_SIZE=100

# exp controlled parameter design
FIX_W=1000
FIX_QUERY_RANGE=$TOTAL_TIME_RANGE
FIX_OVERLAP_PERCENTAGE=10
FIX_DELETE_PERCENTAGE=49
FIX_DELETE_RANGE=10

############################
# Experimental parameter design:
#
# [EXP1] Varying the number of time spans w
# (1) w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP2] Varying query time range
# (1) w: 100
# (2) query range: 1%,5%,10%,20%,40%,60%,80%,100% of totalRange
# - corresponding estimated chunks per interval = 1%,5%,10%,20%,40%,60%,80%,100% of kmax
# - kMax=(pointNum/chunkSize)/w, when range = 100% of totalRange.
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP3] Varying chunk overlap percentage
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 0%, 10%, 30%, 50%, 70%, 90%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP4] Varying delete percentage
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%, 9%, 29%, 49%, 69%, 89%
# (5) delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
#
# [EXP5] Varying delete time range
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 49%
# (5) delete time range: 10%, 30%, 50%, 70%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
############################
echo 3 |sudo tee /proc/sys/vm/drop_caches

ps -ef|grep 'java'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'iotdb'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'dev/null'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'RcvTime'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'BallSpeed'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'MF03'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'KOB'|awk '{print $2}'|xargs kill -9

ps -ef|grep 'influx'|awk '{print $2}'|xargs kill -9

echo 3 |sudo tee /proc/sys/vm/drop_caches

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
$HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

# properties for cpv
$HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
# properties for moc
$HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# write data
echo "Writing O_10_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh /dev/null 2>&1 &
sleep 5s
# Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


# query data
echo "Querying O_10_D_0_0 with varied w"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
mkdir vary_w
cd vary_w

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000 12000 16000 20000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w moc >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMOC.csv
  let i+=1
done

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w mac >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMAC.csv
  let i+=1
done

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w cpv >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

#########################
# export results
#########################
# [EXP1]
# w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
cd vary_w
cat result.csv >$HOME_PATH/${DATASET}_testspace/exp1.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp1, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/w,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp1.csv
line=2
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  #let c=${pointNum}/${chunkSize}/$w # note bash only does the integer division
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/$w) | bc )
  sed -i -e ${line}"s/^/${w},${c},/" $HOME_PATH/${DATASET}_testspace/exp1.csv
  let line+=1
done

############################
# [EXP2] Varying query time range
# (1) w: 100
# (2) query range: 1%,5%,10%,20%,40%,60%,80%,100% of totalRange
# - corresponding estimated chunks per interval = 1%,5%,10%,20%,40%,60%,80%,100% of kmax
# - kMax=(pointNum/chunkSize)/w, when range = 100% of totalRange.
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
############################
echo "Querying O_10_D_0_0 with varied tqe"

cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
mkdir vary_tqe
cd vary_tqe

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for per in 1 5 10 20 40 60 80 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"
  #  range=$((echo scale=0 ; echo ${k}*${FIX_W}*${TOTAL_TIME_RANGE}*${IOTDB_CHUNK_POINT_SIZE}/${TOTAL_POINT_NUMBER}) | bc )
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_W} moc >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMOC.csv
  let i+=1
done

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for per in 1 5 10 20 40 60 80 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_W} mac >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMAC.csv
  let i+=1
done

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for per in 1 5 10 20 40 60 80 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_W} cpv >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

#########################
# export results
#########################
# [EXP2]
# w: 100
# query range: k*w*totalRange/(pointNum/chunkSize).
# - target estimated chunks per interval = k
# - range = k*w*totalRange/(pointNum/chunkSize)
# - kMax=(pointNum/chunkSize)/w, that is, range=totalRange.
# - E.g. k=0.2,0.5,1,2.5,5,12
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
cd vary_tqe
cat result.csv >$HOME_PATH/${DATASET}_testspace/exp2.csv

# 把exp1里FIX_W的那一行结果追加到exp2.csv最后一行，且不要前两列
sed -n -e "/^${FIX_W},/p" $HOME_PATH/${DATASET}_testspace/exp1.csv > tmp # 这里日后改成自动判断取出那一行w=FIX_W的，而不是写死的行数
cut -d "," -f 3- tmp >> $HOME_PATH/${DATASET}_testspace/exp2.csv # 不要前两列
rm tmp

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp2, estimated chunks per interval=k
sed -i -e 1's/^/range,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp2.csv
line=2
for per in 1 5 10 20 40 60 80 100 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  c=$((echo scale=0 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}*${per}/100) | bc )
  sed -i -e ${line}"s/^/${range},${c},/" $HOME_PATH/${DATASET}_testspace/exp2.csv
  let line+=1
done

############################
# O_0_D_0_0
# O_30_D_0_0
# O_50_D_0_0
# O_70_D_0_0
# O_90_D_0_0
############################
for overlap_percentage in 0 30 50 70 90
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
  # properties for cpv
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
  # properties for moc
  $HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

  # write data
  echo "Writing ${workspace}"
  cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 5s
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_${overlap_percentage} 0 0 0 1
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # query data
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix
  cd fix

  echo "moc"
  mkdir moc
  cd moc
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} moc >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

  echo "mac"
  cd ..
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} mac >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  echo "cpv"
  cd ..
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # unify results
  cd ..
  cp $HOME_PATH/SumResultUnify.* .
  java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
done

#########################
# export results
#########################
# [EXP3]
# w: 100
# query range: totalRange
# overlap percentage: 0%, 10%, 30%, 50%, 70%, 90%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_0_D_0_0
cd fix
cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv #带表头

# 把exp1.csv里的w=FIX_W那一行复制到exp3.csv里作为overlap percentage 10%的结果
# sed -n '8,8p' $HOME_PATH/${DATASET}_testspace/exp1.csv >> $HOME_PATH/${DATASET}_testspace/exp4.csv
sed -n -e "/^${FIX_W},/p" $HOME_PATH/${DATASET}_testspace/exp1.csv > tmp # 这里日后改成自动判断取出那一行w=FIX_W的，而不是写死的行数
cut -d "," -f 3- tmp >> $HOME_PATH/${DATASET}_testspace/exp3.csv # 不要前两列
rm tmp

cd $HOME_PATH/${DATASET}_testspace/O_30_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_50_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_70_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_90_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv


# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp3, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/overlap percentage,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp3.csv
line=2
for op in 0 10 30 50 70 90
do
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}) | bc )
  sed -i -e ${line}"s/^/${op},${c},/" $HOME_PATH/${DATASET}_testspace/exp3.csv
  let line+=1
done

############################
# O_10_D_9_10
# O_10_D_29_10
# O_10_D_49_10
# O_10_D_69_10
# O_10_D_89_10
############################
for delete_percentage in 9 29 49 69 89
do
  workspace="O_10_D_${delete_percentage}_10"
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
  # properties for cpv
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
  # properties for moc
  $HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

  # write data
  echo "Writing ${workspace}"
  cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 5s
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 ${delete_percentage} ${FIX_DELETE_RANGE} 0 1
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # query data
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix
  cd fix

  echo "moc"
  mkdir moc
  cd moc
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} moc >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

  echo "mac"
  cd ..
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} mac >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  echo "cpv"
  cd ..
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # unify results
  cd ..
  cp $HOME_PATH/SumResultUnify.* .
  java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
done

#########################
# export results
#########################
# [EXP4]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%, 9%, 29%, 49%, 69%, 89%
# delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
cd $HOME_PATH/${DATASET}_testspace/O_10_D_29_10
cd fix
sed -n '1,1p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv #只是复制表头

# 把exp1.csv里的w=FIX_W那一行复制到exp4.csv里作为delete percentage 10%的结果
# sed -n '8,8p' $HOME_PATH/${DATASET}_testspace/exp1.csv >> $HOME_PATH/${DATASET}_testspace/exp4.csv
sed -n -e "/^${FIX_W},/p" $HOME_PATH/${DATASET}_testspace/exp1.csv > tmp # 这里日后改成自动判断取出那一行w=FIX_W的，而不是写死的行数
cut -d "," -f 3- tmp >> $HOME_PATH/${DATASET}_testspace/exp4.csv # 不要前两列
rm tmp

cd $HOME_PATH/${DATASET}_testspace/O_10_D_9_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_29_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_69_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_89_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp4, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/delete percentage,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp4.csv
line=2
for dp in 0 9 29 49 69 89
do
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}) | bc )
  sed -i -e ${line}"s/^/${dp},${c},/" $HOME_PATH/${DATASET}_testspace/exp4.csv
  let line+=1
done

############################
# O_10_D_49_30
# O_10_D_49_50
# O_10_D_49_70
# O_10_D_49_90
############################
for delete_range in 30 50 70 90
do
  workspace="O_10_D_49_${delete_range}"
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
  # properties for cpv
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
  # properties for moc
  $HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

  # write data
  echo "Writing ${workspace}"
  cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 5s
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 ${FIX_DELETE_PERCENTAGE} ${delete_range} 0 1
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # query data
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix
  cd fix

  echo "moc"
  mkdir moc
  cd moc
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} moc >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

  echo "mac"
  cd ..
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} mac >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  echo "cpv"
  cd ..
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # unify results
  cd ..
  cp $HOME_PATH/SumResultUnify.* .
  java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
done

#########################
# export results
#########################
# [EXP5]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 49%
# delete time range: 10%, 30%, 50%, 70%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_10
cd fix
cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv #带表头

cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_30
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_50
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_70
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_90
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp4, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/delete time range,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp5.csv
line=2
for dr in 10 30 50 70 90
do
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}) | bc )
  sed -i -e ${line}"s/^/${dr},${c},/" $HOME_PATH/${DATASET}_testspace/exp5.csv
  let line+=1
done



echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m