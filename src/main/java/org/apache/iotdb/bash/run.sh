#!/bin/bash

HOME_PATH=/data/rl/v2
DATASET=BallSpeed # "BallSpeed" "KOB" "MF03" "RcvTime"
TOTAL_TIME_RANGE=617426057627
TOTAL_POINT_NUMBER=1200000
IOTDB_CHUNK_POINT_SIZE=1000
FIX_W=100

############################
# generate out-of-order source data.
# Vary overlap percentage: 0%,10%,30%,50%,70%,90%
# Usage: java OverlapGenerator inPath outPath timeIdx valueIdx overlapPercentage overlapDepth
# overlapPercentage: [0,100]
# overlapDepth: [0,50]
############################
cd $HOME_PATH/${DATASET}
cp ${DATASET}.csv ${DATASET}-O_0_0
java OverlapGenerator ${DATASET}.csv ${DATASET}-O_10_10 0 1 10 10
java OverlapGenerator ${DATASET}.csv ${DATASET}-O_30_10 0 1 30 10
java OverlapGenerator ${DATASET}.csv ${DATASET}-O_50_10 0 1 50 10
java OverlapGenerator ${DATASET}.csv ${DATASET}-O_70_10 0 1 70 10
java OverlapGenerator ${DATASET}.csv ${DATASET}-O_90_10 0 1 90 10

############################
# Experimental parameter design:
#
# [EXP1] Varying the number of time spans w
# (1) w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# (2) uery range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP2] Varying query time range
# (1) w: 100
# (2) query range: k*w*totalRange/(pointNum/chunkSize).
# - target estimated chunks per interval = k
# - range = k*w*totalRange/(pointNum/chunkSize)
# - kMax=(pointNum/chunkSize)/w, that is, range=totalRange.
# - E.g. k=0.2,0.5,1,2.5,5,12
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

############################
# [EXP1] Varying the number of time spans w
# (1) w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# (2) uery range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
############################

############################
# O_10_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_0_0
cd O_10_10_D_0_0

# prepare IoTDB config properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties
./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

# properties for cpv
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
# properties for moc
./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# write data
echo "Writing O_10_10_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
# Usage: java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


# query data
echo "Querying O_10_10_D_0_0 with varied w"
cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_0_0
mkdir vary_w
cd vary_w

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  # Usage: ./query_experiment.sh tqe w approach
  ./../../../query_experiment.sh ${TOTAL_TIME_RANGE} $w 2 >> result_${i}.txt
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
  # Usage: ./query_experiment.sh tqe w approach
  ./../../../query_experiment.sh ${TOTAL_TIME_RANGE} $w 1 >> result_${i}.txt
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
  # Usage: ./query_experiment.sh tqe w approach
  ./../../../query_experiment.sh ${TOTAL_TIME_RANGE} $w 3 >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# [EXP2] Varying query time range
# (1) w: 100
# (2) query range: k*w*totalRange/(pointNum/chunkSize).
# - target estimated chunks per interval = k
# - range = k*w*totalRange/(pointNum/chunkSize)
# - kMax=(pointNum/chunkSize)/w, that is, range=totalRange.
# - E.g. k=0.2,0.5,1,2.5,5,12
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
############################
echo "Querying O_10_10_D_0_0 with varied tqe"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_0_0
mkdir vary_tqe
cd vary_tqe

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
w=100
for k in 0.2 0.5 1 2.5 5 12
do
  range=$((echo scale=0 ; echo ${k}*${FIX_W}*${TOTAL_TIME_RANGE}*${IOTDB_CHUNK_POINT_SIZE}/${TOTAL_POINT_NUMBER}) | bc )
  # Usage: ./query_experiment.sh tqe w approach
  ./../../../query_experiment.sh ${range} ${FIX_W} 2 >> result_${i}.txt
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
w=100
for k in 0.2 0.5 1 2.5 5 12
do
  range=$((echo scale=0 ; echo ${k}*${FIX_W}*${TOTAL_TIME_RANGE}*${IOTDB_CHUNK_POINT_SIZE}/${TOTAL_POINT_NUMBER}) | bc )
  # Usage: ./query_experiment.sh tqe w approach
  ./../../../query_experiment.sh ${range} ${FIX_W} 1 >> result_${i}.txt
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
w=100
for k in 0.2 0.5 1 2.5 5 12
do
  range=$((echo scale=0 ; echo ${k}*${FIX_W}*${TOTAL_TIME_RANGE}*${IOTDB_CHUNK_POINT_SIZE}/${TOTAL_POINT_NUMBER}) | bc )
  # Usage: ./query_experiment.sh tqe w approach
  ./../../../query_experiment.sh ${range} ${FIX_W} 3 >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# [EXP3] Varying chunk overlap percentage
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 0%, 10%, 30%, 50%, 70%, 90%
# (4) delete percentage: 0%
# (5) delete time range: 0
############################

############################
# O_0_0_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_0_0_D_0_0
cd O_0_0_D_0_0

# prepare IoTDB config properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_0_0_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_0_0_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_0_0_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties
./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

# properties for cpv
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

# properties for moc
./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# write data
echo "Writing O_0_0_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
# Usage: java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_0_0 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches

# query data
echo "Querying O_0_0_D_0_0"
cd $HOME_PATH/${DATASET}_testspace/O_0_0_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_30_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_30_10_D_0_0
cd O_30_10_D_0_0

# prepare IoTDB config properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_30_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_30_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_30_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties
./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

# properties for cpv
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

# properties for moc
./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# write data
echo "Writing O_30_10_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
# Usage: java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_30_10 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches

# query data
echo "Querying O_30_10_D_0_0"
cd $HOME_PATH/${DATASET}_testspace/O_30_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_50_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_50_10_D_0_0
cd O_50_10_D_0_0

# prepare IoTDB config properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_50_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_50_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_50_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties
./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

# prepare for cpv
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

# prepare for moc
./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# write data
echo "Writing O_50_10_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
# Usage: java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_50_10 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches

# query data
echo "Querying O_50_10_D_0_0"
cd $HOME_PATH/${DATASET}_testspace/O_50_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# Usage: ./query_experiment.sh tqe w approach
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} ${FIX_W} 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

# unify results
cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_70_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_70_10_D_0_0
cd O_70_10_D_0_0

# prepare IoTDB config properties
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_70_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_70_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_70_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_70_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_70_10 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_70_10_D_0_0"

cd $HOME_PATH/${DATASET}_testspace/O_70_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_90_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_90_10_D_0_0
cd O_90_10_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_90_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_90_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_90_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_90_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_90_10 0 0 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_90_10_D_0_0"

cd $HOME_PATH/${DATASET}_testspace/O_90_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

# [EXP4]
# ---- O_10_10_D_0_0
# ---- O_10_10_D_9_10
# ---- O_10_10_D_29_10
# ---- O_10_10_D_49_10
# ---- O_10_10_D_69_10
# ---- O_10_10_D_89_10

############################
# O_10_10_D_9_10
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_9_10
cd O_10_10_D_9_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_9_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_9_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_9_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_9_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 9 10 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_9_10"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_9_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_29_10
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_29_10
cd O_10_10_D_29_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_29_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_29_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_29_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_29_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 29 10 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_29_10"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_29_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_10
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_49_10
cd O_10_10_D_49_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 49 10 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_10"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_69_10
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_69_10
cd O_10_10_D_69_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_69_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_69_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_69_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_69_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 69 10 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_69_10"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_69_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_89_10
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_89_10
cd O_10_10_D_89_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_89_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_89_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_89_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_89_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 89 10 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_89_10"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_89_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

# [EXP5-2]
# ---- O_10_10_D_49_30
# ---- O_10_10_D_49_50
# ---- O_10_10_D_49_70
# ---- O_10_10_D_49_90

############################
# O_10_10_D_49_30
############################
cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_49_30
cd O_10_10_D_49_30

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_30/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_30/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_30/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_30"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 49 30 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_30"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_30
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_50
############################
cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_49_50
cd O_10_10_D_49_50

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_50/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_50/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_50/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_50"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 49 50 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_50"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_50
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_70
############################
cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_49_70
cd O_10_10_D_49_70

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_70/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_70/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_70/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_70"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 49 70 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_70"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_70
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_90
############################
cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_10_D_49_90
cd O_10_10_D_49_90

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_90/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_90/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_10_D_49_90/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_90"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 5s
java -jar $HOME_PATH/${DATASET}_testspace/Write${DATASET}-0.12.4.jar $HOME_PATH/${DATASET}/${DATASET}-O_10_10 49 90 0 1
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_90"

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_90
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh ${TOTAL_TIME_RANGE} 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

#########################
# export results
#########################
HOME_PATH=/data/rl/v2

# [EXP1]
# w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_0_0
cd vary_w
cat result.csv >$HOME_PATH/${DATASET}_testspace/exp1.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp1, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/w,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp1.csv
line=2
pointNum=1200000
chunkSize=1000
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  #let c=${pointNum}/${chunkSize}/$w # note bash only does the integer division
  c=$((echo scale=3 ; echo ${pointNum}/${chunkSize}/$w) | bc )
  sed -i -e ${line}"s/^/${w},${c},/" $HOME_PATH/${DATASET}_testspace/exp1.csv
  let line+=1
done

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
cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_0_0
cd vary_tqe
cat result.csv >$HOME_PATH/${DATASET}_testspace/exp2.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp2, estimated chunks per interval=k
sed -i -e 1's/^/range,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp2.csv
line=2
pointNum=1200000
chunkSize=1000
totalRange=${TOTAL_TIME_RANGE}
w=100
for k in 0.2 0.5 1 2.5 5 12
do
  #let range=${k}*${w}*${totalRange}*${chunkSize}/${pointNum} # note bash only does the integer division
  range=$((echo scale=3 ; echo ${k}*${w}*${totalRange}*${chunkSize}/${pointNum}) | bc )
  sed -i -e ${line}"s/^/${range},${k},/" $HOME_PATH/${DATASET}_testspace/exp2.csv
  let line+=1
done


# [EXP3]
# w: 100
# query range: totalRange
# overlap percentage: 0%, 10%, 30%, 50%, 70%, 90%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_0_0_D_0_0
cd fix
cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv #带表头

# 把exp1.csv里的w=100那一行复制到exp3.csv里作为overlap percentage 10%的结果
# ATTENTION: 这里日后改成自动判断取出那一行参数是100的，而不是写死的行数
sed -n '8,8p' $HOME_PATH/${DATASET}_testspace/exp1.csv >> $HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_30_10_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_50_10_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_70_10_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

cd $HOME_PATH/${DATASET}_testspace/O_90_10_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv


# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp3, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/overlap percentage,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp3.csv
line=2
pointNum=1200000
chunkSize=1000
w=100
for op in 0 10 30 50 70 90
do
  c=$((echo scale=3 ; echo ${pointNum}/${chunkSize}/$w) | bc )
  sed -i -e ${line}"s/^/${op},${c},/" $HOME_PATH/${DATASET}_testspace/exp3.csv
  let line+=1
done

# [EXP4]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%, 9%, 29%, 49%, 69%, 89%
# delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_9_10
cd fix
cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv #带表头

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_29_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_69_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_89_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp4, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/delete percentage,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp4.csv
line=2
pointNum=1200000
chunkSize=1000
w=100
for dp in 0 9 29 49 69 89
do
  c=$((echo scale=3 ; echo ${pointNum}/${chunkSize}/$w) | bc )
  sed -i -e ${line}"s/^/${dp},${c},/" $HOME_PATH/${DATASET}_testspace/exp4.csv
  let line+=1
done

# [EXP5]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 49%
# delete time range: 10%, 30%, 50%, 70%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_10
cd fix
cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv #带表头

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_30
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_50
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_70
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

cd $HOME_PATH/${DATASET}_testspace/O_10_10_D_49_90
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp4, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/delete time range,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp5.csv
line=2
pointNum=1200000
chunkSize=1000
w=100
for dr in 10 30 50 70 90
do
  c=$((echo scale=3 ; echo ${pointNum}/${chunkSize}/$w) | bc )
  sed -i -e ${line}"s/^/${dr},${c},/" $HOME_PATH/${DATASET}_testspace/exp5.csv
  let line+=1
done